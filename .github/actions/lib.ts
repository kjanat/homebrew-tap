export function input(name: string, options: { required?: boolean } = {}): string {
	const value = Deno.env.get(`INPUT_${name.replaceAll(' ', '_').toUpperCase()}`) ?? '';
	if (options.required === true && value === '') throw new Error(`input '${name}' is required`);
	return value;
}

export async function setOutput(name: string, value: string | object): Promise<void> {
	const file = Deno.env.get('GITHUB_OUTPUT');
	if (file === undefined) throw new Error('GITHUB_OUTPUT is not set');
	const text = typeof value === 'string' ? value : JSON.stringify(value);
	const delimiter = `out_${crypto.randomUUID()}`;
	await Deno.writeTextFile(file, `${name}<<${delimiter}\n${text}\n${delimiter}\n`, { append: true });
}

export function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === 'object' && value !== null;
}

export async function run(command: string, args: string[], env: Record<string, string> = {}): Promise<string> {
	const output = await new Deno.Command(command, { args, env, stdout: 'piped', stderr: 'inherit' }).output();
	if (!output.success) throw new Error(`${command} ${args.join(' ')} exited with ${output.code}`);
	return new TextDecoder().decode(output.stdout).trim();
}

export async function remoteBranchExists(branch: string): Promise<boolean> {
	const output = await new Deno.Command('git', {
		args: ['ls-remote', '--exit-code', '--heads', 'origin', branch],
		stdout: 'null',
		stderr: 'inherit',
	}).output();
	if (output.code !== 0 && output.code !== 2) throw new Error(`git ls-remote exited with ${output.code}`);
	return output.code === 0;
}

export interface Asset {
	name: string;
	url: string;
	digest: string | null;
	size: number;
}

export interface Release {
	tagName: string;
	assets: Asset[];
}

export function parseAsset(value: unknown): Asset {
	if (
		!isRecord(value)
		|| typeof value.name !== 'string'
		|| typeof value.url !== 'string'
		|| (typeof value.digest !== 'string' && value.digest !== null)
		|| typeof value.size !== 'number'
	) throw new Error(`unexpected asset shape: ${JSON.stringify(value)}`);
	return { name: value.name, url: value.url, digest: value.digest, size: value.size };
}

export function parseRelease(value: unknown): Release {
	if (!isRecord(value) || typeof value.tagName !== 'string' || !Array.isArray(value.assets)) {
		throw new Error(`unexpected release shape: ${JSON.stringify(value)}`);
	}
	return { tagName: value.tagName, assets: value.assets.map(parseAsset) };
}

export async function viewRelease(repo: string, tag: string): Promise<Release> {
	const args = ['release', 'view', ...(tag === '' ? [] : [tag]), '--repo', repo, '--json', 'tagName,assets'];
	return parseRelease(JSON.parse(await run('gh', args)));
}

export function selectAssets(assets: Asset[], filter: string): Asset[] {
	if (filter === '') return assets;
	const pattern = new RegExp(filter);
	return assets.filter((asset) => pattern.test(asset.name));
}

export interface Replacement {
	path: string;
	count: number;
}

export function replaceAll(text: string, search: string, replace: string): { text: string; count: number } {
	if (search === '') throw new Error('search must not be empty');
	const count = text.split(search).length - 1;
	return { text: text.replaceAll(search, replace), count };
}

export function parseFileList(value: string): string[] {
	return value.split('\n').map((line) => line.trim()).filter((line) => line !== '');
}

export interface Digest {
	name: string;
	digest: string;
}

export interface Update {
	text: string;
	previous: string;
	changed: boolean;
}

const VERSION_STANZA = /^(\s*)version "([^"]+)"$/m;
const SHA256_URL_PAIR = /^(\s*)sha256 "[0-9a-f]{64}"\n(\s*url "([^"]+)")$/gm;

export function parseDigests(value: unknown): Digest[] {
	if (!Array.isArray(value)) throw new Error('assets must be a JSON array');
	return value.map((asset) => {
		if (!isRecord(asset) || typeof asset.name !== 'string') {
			throw new Error(`unexpected asset shape: ${JSON.stringify(asset)}`);
		}
		if (typeof asset.digest !== 'string') throw new Error(`asset ${asset.name} has no digest`);
		return { name: asset.name, digest: asset.digest.replace(/^sha256:/, '') };
	});
}

export function updateCask(text: string, version: string, assets: Digest[]): Update {
	const versionMatch = VERSION_STANZA.exec(text);
	if (versionMatch === null) throw new Error('cask has no version stanza');
	const [stanza, indent, previous] = versionMatch;
	const digests = new Map(assets.map((asset) => [asset.name, asset.digest]));
	const missing: string[] = [];

	let updated = text.replace(stanza, `${indent}version "${version}"`);
	updated = updated.replace(SHA256_URL_PAIR, (pair, shaIndent: string, urlLine: string, urlTemplate: string) => {
		const name = urlTemplate.replaceAll('#{version}', version).split('/').at(-1) ?? '';
		const digest = digests.get(name);
		if (digest === undefined) {
			missing.push(name);
			return pair;
		}
		return `${shaIndent}sha256 "${digest}"\n${urlLine}`;
	});

	if (missing.length > 0) throw new Error(`no asset digest for: ${missing.join(', ')}`);
	return { text: updated, previous: previous ?? '', changed: updated !== text };
}
