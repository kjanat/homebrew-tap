import { assertEquals, assertMatch, assertNotMatch } from 'jsr:@std/assert@1';
import { parse } from 'jsr:@std/yaml@1';
import { isRecord } from './lib.ts';

function runStep(metadata: unknown): string | undefined {
	if (!isRecord(metadata) || !isRecord(metadata.runs) || !Array.isArray(metadata.runs.steps)) return undefined;
	for (const step of metadata.runs.steps) {
		if (isRecord(step) && typeof step.run === 'string') return step.run;
	}
	return undefined;
}

async function runAction(action: string, inputs: Record<string, string>, files: Record<string, string>) {
	const temp = await Deno.makeTempDir({ prefix: 'homebrew-action-test-' });
	try {
		const script = runStep(parse(await Deno.readTextFile(new URL(`${action}/action.yml`, import.meta.url))));
		if (script === undefined) throw new Error(`${action} has no run step`);
		const repository = 'fixture/homebrew-tap';
		const sha = '0'.repeat(40);
		const helper = `https://raw.githubusercontent.com/${repository}/${sha}/.github/actions/lib.ts`;
		await Deno.writeTextFile(
			`${temp}/step.ts`,
			script
				.replaceAll('${{ github.repository }}', repository)
				.replaceAll('${{ github.sha }}', sha),
		);
		await Deno.writeTextFile(
			`${temp}/imports.json`,
			JSON.stringify({
				imports: { [helper]: new URL('lib.ts', import.meta.url).href },
			}),
		);
		await Deno.writeTextFile(`${temp}/output`, '');
		for (const [name, text] of Object.entries(files)) await Deno.writeTextFile(`${temp}/${name}`, text);
		const result = await new Deno.Command(Deno.execPath(), {
			args: ['run', '--no-lock', '--allow-all', `--import-map=${temp}/imports.json`, `${temp}/step.ts`],
			cwd: temp,
			env: {
				GITHUB_OUTPUT: `${temp}/output`,
				...Object.fromEntries(Object.entries(inputs).map(([name, value]) => [`INPUT_${name.toUpperCase()}`, value])),
			},
			stdout: 'piped',
			stderr: 'piped',
		}).output();
		const output = await Deno.readTextFile(`${temp}/output`);
		const outputs = Object.fromEntries([...output.matchAll(/^([^\n]+)<<([^\n]+)\n([\s\S]*?)\n\2\n/gm)]
			.map((match) => [match[1], match[3]]));
		const updated = Object.fromEntries(
			await Promise.all(Object.keys(files).map(async (name) => [name, await Deno.readTextFile(`${temp}/${name}`)])),
		);
		return { success: result.success, stderr: new TextDecoder().decode(result.stderr), outputs, files: updated };
	} finally {
		await Deno.remove(temp, { recursive: true });
	}
}

const cask = `cask "tool" do
  version "1.0.0"

  on_macos do
    sha256 "${'a'.repeat(64)}"
    url "https://example.com/v#{version}/tool-v#{version}.darwin.tar.xz"
  end
  on_linux do
    sha256 "${'b'.repeat(64)}"
    url "https://example.com/v#{version}/tool-v#{version}.linux.tar.xz"
  end
end
`;
const assets = [
	{ name: 'tool-v2.0.0.darwin.tar.xz', digest: 'c'.repeat(64) },
	{ name: 'tool-v2.0.0.linux.tar.xz', digest: 'd'.repeat(64) },
	{ name: 'tool-v2.0.0.zip', digest: 'e'.repeat(64) },
];
const update = (digests: unknown, text = cask, version = '2.0.0') =>
	runAction('update-cask', { cask: 'cask.rb', version, assets: JSON.stringify(digests) }, { 'cask.rb': text });

Deno.test('update-cask rewrites the version and each matching digest', async () => {
	const result = await update(assets.map((asset) => ({ ...asset, digest: `sha256:${asset.digest}` })));
	assertEquals(result.success, true, result.stderr);
	assertEquals(result.outputs, { changed: 'true', 'previous-version': '1.0.0' });
	assertMatch(result.files['cask.rb'], /^ {2}version "2\.0\.0"$/m);
	assertMatch(result.files['cask.rb'], new RegExp(`sha256 "${'c'.repeat(64)}"\\n {4}url ".*darwin`));
	assertMatch(result.files['cask.rb'], new RegExp(`sha256 "${'d'.repeat(64)}"\\n {4}url ".*linux`));
	assertNotMatch(result.files['cask.rb'], /aaaa|bbbb/);
});

Deno.test('update-cask leaves a current cask unchanged', async () => {
	const result = await update(
		[
			{ name: 'tool-v1.0.0.darwin.tar.xz', digest: 'a'.repeat(64) },
			{ name: 'tool-v1.0.0.linux.tar.xz', digest: 'b'.repeat(64) },
		],
		cask,
		'1.0.0',
	);
	assertEquals(result.success, true, result.stderr);
	assertEquals(result.outputs.changed, 'false');
	assertEquals(result.files['cask.rb'], cask);
});

Deno.test('update-cask fails without writing when an asset is missing', async () => {
	const result = await update(assets.slice(0, 1));
	assertEquals(result.success, false);
	assertMatch(result.stderr, /no asset digest for: tool-v2\.0\.0\.linux\.tar\.xz/);
	assertEquals(result.files['cask.rb'], cask);
});

Deno.test('update-cask rejects a cask without a version', async () => {
	const result = await update([], 'cask "x" do\nend\n');
	assertEquals(result.success, false);
	assertMatch(result.stderr, /cask has no version stanza/);
});

Deno.test('update-cask rejects absent digests and non-array assets', async () => {
	for (
		const [assets, message] of [
			[[{ name: 'old', digest: null }], /asset old has no digest/],
			[{}, /assets must be a JSON array/],
		] as const
	) {
		const result = await update(assets);
		assertEquals(result.success, false);
		assertMatch(result.stderr, message);
		assertEquals(result.files['cask.rb'], cask);
	}
});

Deno.test('replace-in-files replaces literal occurrences and reports counts', async () => {
	const result = await runAction('replace-in-files', { files: 'a', search: 'a.b', replace: 'c' }, { a: 'a.b a.b axb' });
	assertEquals(result.success, true, result.stderr);
	assertEquals(result.files.a, 'c c axb');
	assertEquals(result.outputs.changed, 'true');
	assertEquals(JSON.parse(result.outputs.replacements), [{ path: 'a', count: 2 }]);
});

Deno.test('replace-in-files leaves unmatched text unchanged', async () => {
	const result = await runAction('replace-in-files', { files: 'a', search: 'x', replace: 'y' }, { a: 'nothing' });
	assertEquals(result.success, true, result.stderr);
	assertEquals(result.files.a, 'nothing');
	assertEquals(result.outputs.changed, 'false');
});

Deno.test('replace-in-files rejects an empty search without writing', async () => {
	const result = await runAction('replace-in-files', { files: 'a', search: '', replace: 'y' }, { a: 'x' });
	assertEquals(result.success, false);
	assertMatch(result.stderr, /input 'search' is required/);
	assertEquals(result.files.a, 'x');
});

Deno.test('replace-in-files parses newline separated paths', async () => {
	const result = await runAction('replace-in-files', { files: 'a\n  b  \n\nc\n', search: 'x', replace: 'y' }, {
		a: 'x',
		b: 'x',
		c: 'x',
	});
	assertEquals(result.success, true, result.stderr);
	assertEquals(result.files, { a: 'y', b: 'y', c: 'y' });
	assertEquals(JSON.parse(result.outputs.replacements), [
		{ path: 'a', count: 1 },
		{ path: 'b', count: 1 },
		{ path: 'c', count: 1 },
	]);
});
