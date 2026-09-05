import { input, isRecord, setOutput } from '../lib/action.ts';

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

function parseAsset(value: unknown): Asset {
	if (
		!isRecord(value)
		|| typeof value.name !== 'string'
		|| typeof value.url !== 'string'
		|| (typeof value.digest !== 'string' && value.digest !== null)
		|| typeof value.size !== 'number'
	) {
		throw new Error(`unexpected asset shape: ${JSON.stringify(value)}`);
	}
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
	const output = await new Deno.Command('gh', { args, stdout: 'piped', stderr: 'inherit' }).output();
	if (!output.success) {
		throw new Error(`gh ${args.join(' ')} exited with ${output.code}`);
	}
	return parseRelease(JSON.parse(new TextDecoder().decode(output.stdout)));
}

export function selectAssets(assets: Asset[], filter: string): Asset[] {
	if (filter === '') {
		return assets;
	}
	const pattern = new RegExp(filter);
	return assets.filter((asset) => pattern.test(asset.name));
}

export async function main(): Promise<void> {
	const release = await viewRelease(input('repo', { required: true }), input('tag'));
	await setOutput('tag', release.tagName);
	await setOutput('version', release.tagName.replace(/^v/, ''));
	await setOutput('assets', selectAssets(release.assets, input('filter')));
}
