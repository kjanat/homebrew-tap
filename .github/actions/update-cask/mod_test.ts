import { assertEquals, assertMatch, assertNotMatch, assertThrows } from 'jsr:@std/assert@1';
import { parseDigests, updateCask } from './mod.ts';

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

Deno.test('rewrites version and every sha256 from the matching asset', () => {
	const result = updateCask(cask, '2.0.0', assets);
	assertEquals(result.changed, true);
	assertEquals(result.previous, '1.0.0');
	assertMatch(result.text, /^ {2}version "2\.0\.0"$/m);
	assertMatch(result.text, new RegExp(`sha256 "${'c'.repeat(64)}"\\n {4}url ".*darwin`));
	assertMatch(result.text, new RegExp(`sha256 "${'d'.repeat(64)}"\\n {4}url ".*linux`));
	assertNotMatch(result.text, /aaaa|bbbb/);
});

Deno.test('reports no change when the version is already current', () => {
	const current = [
		{ name: 'tool-v1.0.0.darwin.tar.xz', digest: 'a'.repeat(64) },
		{ name: 'tool-v1.0.0.linux.tar.xz', digest: 'b'.repeat(64) },
	];
	const result = updateCask(cask, '1.0.0', current);
	assertEquals(result.changed, false);
	assertEquals(result.text, cask);
});

Deno.test('fails when an asset for a url is missing', () => {
	assertThrows(
		() => updateCask(cask, '2.0.0', assets.slice(0, 1)),
		Error,
		'no asset digest for: tool-v2.0.0.linux.tar.xz',
	);
});

Deno.test('fails when the cask has no version stanza', () => {
	assertThrows(() => updateCask('cask "x" do\nend\n', '1', []), Error, 'no version stanza');
});

Deno.test('parseDigests strips the sha256 prefix and rejects assets without a digest', () => {
	assertEquals(parseDigests([{ name: 'a', digest: `sha256:${'f'.repeat(64)}` }]), [
		{ name: 'a', digest: 'f'.repeat(64) },
	]);
	assertThrows(() => parseDigests([{ name: 'old', digest: null }]), Error, 'asset old has no digest');
	assertThrows(() => parseDigests({}), Error, 'must be a JSON array');
});
