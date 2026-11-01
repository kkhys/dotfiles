/**
 * Rule matching for the permission gate. Pure functions so they can be tested
 * without pi: `node --test rules.test.ts`.
 *
 * Patterns are globs. For commands `*` matches anything; for paths `*` stays
 * inside one segment and `**` crosses segments. A path pattern starting with
 * `/` or `~` is matched against the absolute path, any other pattern against
 * its tail, so `.env` matches `/repo/.env` and `**\/secrets/*.age` matches
 * `/repo/nix/secrets/key.age`.
 */

export type Tool = "bash" | "read" | "edit" | "write";
export type Decision = "deny" | "ask";

export type Rules = Partial<Record<Decision, Partial<Record<Tool, string[]>>>>;

export interface Verdict {
	decision: Decision;
	pattern: string;
}

function escapeRegExp(s: string): string {
	return s.replace(/[.+^${}()|[\]\\]/g, "\\$&");
}

export function commandPattern(pattern: string): RegExp {
	const source = escapeRegExp(pattern).replace(/\*/g, ".*").replace(/\?/g, ".");
	return new RegExp(`^${source}$`);
}

export function pathPattern(pattern: string, home: string): RegExp {
	let expanded = pattern;
	if (expanded.startsWith("~/")) expanded = `${home}/${expanded.slice(2)}`;
	else if (expanded.startsWith("//")) expanded = expanded.slice(1);

	const source = escapeRegExp(expanded)
		.replace(/\*\*\//g, "\u0000SEGS\u0000")
		.replace(/\*\*/g, "\u0000ALL\u0000")
		.replace(/\*/g, "[^/]*")
		.replace(/\?/g, "[^/]")
		.replace(/\u0000SEGS\u0000/g, "(?:.*/)?")
		.replace(/\u0000ALL\u0000/g, ".*");

	const anchor = expanded.startsWith("/") ? "^" : "(?:^|/)";
	return new RegExp(`${anchor}${source}$`);
}

function firstMatch(subject: string, patterns: string[], toRegExp: (p: string) => RegExp): string | undefined {
	return patterns.find((p) => toRegExp(p).test(subject));
}

/** Returns the first rule that applies, deny rules before ask rules. */
export function decide(rules: Rules, tool: Tool, subject: string, home: string): Verdict | undefined {
	const toRegExp = tool === "bash" ? commandPattern : (p: string) => pathPattern(p, home);
	for (const decision of ["deny", "ask"] as const) {
		const pattern = firstMatch(subject, rules[decision]?.[tool] ?? [], toRegExp);
		if (pattern) return { decision, pattern };
	}
	return undefined;
}
