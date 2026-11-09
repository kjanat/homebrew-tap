const caskPath = Deno.args[0] ?? 'Casks/shellcheck.rb';
const source = await Deno.readTextFile(caskPath);
const pattern = /version "([0-9]+\.[0-9]+\.[0-9]+)"\r?\n\s+sha256 "([a-f0-9]{64})"\r?\n\s+url "([^"]+)"/g;
const assets = [...source.matchAll(pattern)].map((match) => {
	const [, version, digest, template] = match;
	if (!version || !digest || !template) throw new Error('Incomplete ShellCheck asset declaration');
	return { version, digest, url: template.replaceAll('#{version}', version) };
});
if (assets.length !== 4 || new Set(assets.map(({ version }) => version)).size !== 1) {
	throw new Error('The four ShellCheck architectures must declare the same version and a SHA-256 checksum');
}
const version = assets[0]?.version;
if (!version) throw new Error('ShellCheck version is missing');
const expectedUrls = new Set(
	['darwin.aarch64', 'darwin.x86_64', 'linux.aarch64', 'linux.x86_64'].map((platform) =>
		`https://github.com/koalaman/shellcheck/releases/download/v${version}/shellcheck-v${version}.${platform}.tar.xz`
	),
);
for (const { url } of assets) {
	if (!expectedUrls.delete(url)) throw new Error(`Unexpected or duplicate ShellCheck asset: ${url}`);
}
for (const file of ['bash/shellcheck', 'fish/shellcheck.fish', 'zsh/_shellcheck', 'powershell/shellcheck.ps1']) {
	const text = await Deno.readTextFile(`completions/shellcheck/${file}`);
	if (text.match(/# ShellCheck ([0-9]+\.[0-9]+\.[0-9]+)/)?.[1] !== version) {
		throw new Error(`Completion header does not match ShellCheck ${version}: ${file}`);
	}
}
await Promise.all(assets.map(async ({ url, digest }) => {
	const response = await fetch(url);
	if (!response.ok) throw new Error(`Download failed (${response.status}): ${url}`);
	const bytes = new Uint8Array(await crypto.subtle.digest('SHA-256', await response.arrayBuffer()));
	const actual = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
	if (actual !== digest) throw new Error(`SHA-256 mismatch: ${url}`);
	console.log(`Verified ${url.split('/').at(-1)}`);
}));
console.log(`ShellCheck ${version}: all four downloads and completion headers match.`);
