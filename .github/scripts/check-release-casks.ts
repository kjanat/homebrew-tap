const packages = [
	{ name: 'runner', repository: 'runner', tagPrefix: 'v', assetPrefix: 'runner-v' },
	{ name: 'svg', repository: 'svg', tagPrefix: 'v', assetPrefix: 'svg-v' },
	{ name: 'rshellcheck', repository: 'shellcheck-rs', tagPrefix: 'rshellcheck-v', assetPrefix: 'rshellcheck-' },
];
const targets = [
	'aarch64-apple-darwin',
	'x86_64-apple-darwin',
	'aarch64-unknown-linux-musl',
	'x86_64-unknown-linux-musl',
];

for (const pkg of packages) {
	const source = await Deno.readTextFile(`Casks/${pkg.name}.rb`);
	const pattern = /version "([0-9]+\.[0-9]+\.[0-9]+)"\r?\n\s+sha256 "([a-f0-9]{64})"\r?\n\s+url "([^"]+)"/g;
	const assets = [...source.matchAll(pattern)].map((match) => {
		const [, version, digest, template] = match;
		if (!version || !digest || !template) throw new Error(`Incomplete ${pkg.name} asset declaration`);
		return { version, digest, url: template.replaceAll('#{version}', version) };
	});
	const version = assets[0]?.version;
	if (!version || assets.length !== targets.length || new Set(assets.map((asset) => asset.version)).size !== 1) {
		throw new Error(`${pkg.name}: all four architectures must declare the same version and a checksum`);
	}
	const expected = new Set(
		targets.map((target) =>
			`https://github.com/kjanat/${pkg.repository}/releases/download/${pkg.tagPrefix}${version}/${pkg.assetPrefix}${version}-${target}.tar.gz`
		),
	);
	for (const { url } of assets) {
		if (!expected.delete(url)) throw new Error(`Unexpected or duplicate ${pkg.name} asset: ${url}`);
	}
	await Promise.all(assets.map(async ({ url, digest }) => {
		const response = await fetch(url);
		if (!response.ok) throw new Error(`Download failed (${response.status}): ${url}`);
		const bytes = new Uint8Array(await crypto.subtle.digest('SHA-256', await response.arrayBuffer()));
		const actual = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
		if (actual !== digest) throw new Error(`SHA-256 mismatch: ${url}`);
		console.log(`Verified ${url.split('/').at(-1)}`);
	}));
}
