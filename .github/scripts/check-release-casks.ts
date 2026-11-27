import { arg, cli, CLIError, command } from 'jsr:@kjanat/dreamcli@^5';

const packages = [
	{
		name: 'fsql',
		repository: 'fsql',
		tagPrefix: 'v',
		assetTemplate: 'fsql-{target}',
		targets: ['aarch64-apple-darwin', 'x86_64-apple-darwin', 'aarch64-unknown-linux-gnu', 'x86_64-unknown-linux-gnu'],
	},
	{ name: 'runner', repository: 'runner', tagPrefix: 'v', assetTemplate: 'runner-v{version}-{target}.tar.gz' },
	{ name: 'svg', repository: 'svg', tagPrefix: 'v', assetTemplate: 'svg-v{version}-{target}.tar.gz' },
	{
		name: 'rshellcheck',
		repository: 'shellcheck-rs',
		tagPrefix: 'rshellcheck-v',
		assetTemplate: 'rshellcheck-{version}-{target}.tar.gz',
	},
	{
		name: 'envctl',
		repository: 'envctl',
		tagPrefix: 'v',
		assetTemplate: 'envctl-{target}',
		targets: ['darwin-arm64', 'darwin-amd64', 'linux-arm64', 'linux-amd64'],
		vendored: [
			{ local: 'manpages/envctl/envctl.1', upstream: 'man/envctl.1' },
			{ local: 'manpages/envctl/LICENSE', upstream: 'LICENSE' },
		],
	},
] as const;
const rustTargets = [
	'aarch64-apple-darwin',
	'x86_64-apple-darwin',
	'aarch64-unknown-linux-musl',
	'x86_64-unknown-linux-musl',
];

type ReleasePackage = (typeof packages)[number];

function readAssets(pkg: ReleasePackage, source: string) {
	const targets = 'targets' in pkg ? pkg.targets : rustTargets;
	const pattern = /version "([0-9]+\.[0-9]+\.[0-9]+)"\r?\n\s+sha256 "([a-f0-9]{64})"\r?\n\s+url "([^"]+)"/g;
	const assets = Array.from(source.matchAll(pattern), ([, version, digest, template]) => ({
		version,
		digest,
		url: template.replaceAll('#{version}', version),
	}));
	const version = assets[0]?.version;
	if (!version || assets.length !== targets.length || assets.some((asset) => asset.version !== version)) {
		throw new CLIError(`${pkg.name}: all ${targets.length} targets must declare the same version and a checksum`, {
			code: 'INVALID_RELEASE',
			details: { cask: pkg.name, targets, versions: assets.map((asset) => asset.version) },
		});
	}

	const tag = pkg.tagPrefix + version;
	const expected = new Set(targets.map((target) => {
		const file = pkg.assetTemplate.replace('{version}', version).replace('{target}', target);
		return `https://github.com/kjanat/${pkg.repository}/releases/download/${tag}/${file}`;
	}));
	for (const { url } of assets) {
		if (!expected.delete(url)) {
			throw new CLIError(`Unexpected or duplicate ${pkg.name} asset: ${url}`, {
				code: 'UNEXPECTED_ASSET',
				details: { cask: pkg.name, tag, url },
			});
		}
	}
	return { assets, version, tag };
}

async function download(url: string) {
	const response = await fetch(url);
	if (!response.ok) {
		throw new CLIError(`Download failed (HTTP ${response.status}): ${url}`, {
			code: 'DOWNLOAD_FAILED',
			details: { url, status: response.status },
		});
	}
	return response;
}

async function verifyCask(pkg: ReleasePackage) {
	const source = await Deno.readTextFile(`Casks/${pkg.name}.rb`);
	const { assets, version, tag } = readAssets(pkg, source);
	const verified = await Promise.all(assets.map(async ({ url, digest }) => {
		const response = await download(url);
		const actual = new Uint8Array(await crypto.subtle.digest('SHA-256', await response.arrayBuffer())).toHex();
		if (actual !== digest) {
			throw new CLIError(`SHA-256 mismatch: ${url}`, {
				code: 'CHECKSUM_MISMATCH',
				details: { url, expected: digest, actual },
			});
		}
		return url.slice(url.lastIndexOf('/') + 1);
	}));

	for (const { local, upstream } of 'vendored' in pkg ? pkg.vendored : []) {
		const url = `https://raw.githubusercontent.com/kjanat/${pkg.repository}/${tag}/${upstream}`;
		const response = await download(url);
		const expected = (await response.text()).replaceAll('\r\n', '\n');
		const actual = (await Deno.readTextFile(local)).replaceAll('\r\n', '\n');
		if (actual !== expected) {
			throw new CLIError(`${local} differs from ${pkg.name} ${tag}`, {
				code: 'VENDORED_FILE_MISMATCH',
				suggest: `Refresh ${local} from ${url}`,
				details: { local, url },
			});
		}
		verified.push(local);
	}
	return verified.map((file) => ({ cask: pkg.name, version, file }));
}

const [first, ...rest] = packages;
const names = [first.name, ...rest.map((pkg) => pkg.name)] as const;
const byName = new Map(packages.map((pkg) => [pkg.name, pkg] as const));
const check = command('check-release-casks')
	.description('Verify release checksums and vendored files for Homebrew casks')
	.arg(
		'casks',
		arg.enum(names).variadic().env('CASK').unique().default([...names]).describe(
			'Casks to verify (comma-separated in CASK)',
		),
	)
	.action(async ({ args, out }) => {
		const rows = [];
		for (const name of args.casks) {
			const spinner = out.spinner(`Checking ${name}`);
			const files = await spinner.wrap(verifyCask(byName.get(name)!), {
				succeed: `Verified ${name}`,
				fail: `Failed to verify ${name}`,
			});
			rows.push(...files);
		}
		if (out.jsonMode || out.verbosity !== 'quiet') {
			out.table(rows, [
				{ key: 'cask', header: 'Cask' },
				{ key: 'version', header: 'Version' },
				{ key: 'file', header: 'Verified file' },
			]);
		}
	});

await cli('check-release-casks').default(check).run();
