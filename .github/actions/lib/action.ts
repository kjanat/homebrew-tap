export function input(name: string, options: { required?: boolean } = {}): string {
	const value = Deno.env.get(`INPUT_${name.replaceAll(' ', '_').toUpperCase()}`) ?? '';
	if (options.required === true && value === '') {
		throw new Error(`input '${name}' is required`);
	}
	return value;
}

export async function setOutput(name: string, value: string | object): Promise<void> {
	const file = Deno.env.get('GITHUB_OUTPUT');
	if (file === undefined) {
		throw new Error('GITHUB_OUTPUT is not set');
	}
	const text = typeof value === 'string' ? value : JSON.stringify(value);
	const delimiter = `out_${crypto.randomUUID()}`;
	await Deno.writeTextFile(file, `${name}<<${delimiter}\n${text}\n${delimiter}\n`, { append: true });
}

export function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === 'object' && value !== null;
}
