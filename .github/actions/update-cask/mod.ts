import { input, isRecord, setOutput } from '../lib/action.ts';

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
	if (!Array.isArray(value)) {
		throw new Error('assets must be a JSON array');
	}
	return value.map((asset) => {
		if (!isRecord(asset) || typeof asset.name !== 'string') {
			throw new Error(`unexpected asset shape: ${JSON.stringify(asset)}`);
		}
		if (typeof asset.digest !== 'string') {
			throw new Error(`asset ${asset.name} has no digest`);
		}
		return { name: asset.name, digest: asset.digest.replace(/^sha256:/, '') };
	});
}

export function updateCask(text: string, version: string, assets: Digest[]): Update {
	const versionMatch = VERSION_STANZA.exec(text);
	if (versionMatch === null) {
		throw new Error('cask has no version stanza');
	}
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

	if (missing.length > 0) {
		throw new Error(`no asset digest for: ${missing.join(', ')}`);
	}
	return { text: updated, previous: previous ?? '', changed: updated !== text };
}

export async function main(): Promise<void> {
	const path = input('cask', { required: true });
	const version = input('version', { required: true });
	const assets = parseDigests(JSON.parse(input('assets', { required: true })));

	const result = updateCask(await Deno.readTextFile(path), version, assets);
	if (result.changed) {
		await Deno.writeTextFile(path, result.text);
	}
	await setOutput('changed', String(result.changed));
	await setOutput('previous-version', result.previous);
}
