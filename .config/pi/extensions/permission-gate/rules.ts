/**
 * Rule matching for the permission gate. Pure functions so they can be tested
 * without pi: `node --test rules.test.ts`.
 *
 * Patterns are globs. For commands `*` matches anything; for paths `*` stays
 * inside one segment and `**` crosses segments. A path pattern starting with
 * `/` or `~` is matched against the absolute path, any other pattern against
 * its tail, so `.env` matches `/repo/.env` and `**\/secrets/*.age` matches
 * `/repo/nix/secrets/key.age`.
 *
 * A command is split at `;`, `&&`, `||`, `|`, `&` and newlines and every
 * segment is checked, so `ls; rm -rf x` is caught by the rm rule. Quotes are
 * not parsed: a separator inside a string splits too, which can only add
 * matches, never hide one.
 */

import { basename, dirname, isAbsolute, join, resolve } from "node:path";

export type Tool = "bash" | "read" | "edit" | "write";
export type Decision = "deny" | "ask";

export type Rules = Partial<Record<Decision, Partial<Record<Tool, string[]>>>>;

export interface Verdict {
	decision: Decision;
	pattern: string;
}

export interface MatchOptions {
	home: string;
	/** macOS file systems ignore case, so `.env` must also catch `.ENV`. */
	ignoreCase?: boolean;
}

function escapeRegExp(s: string): string {
	return s.replace(/[.+^${}()|[\]\\]/g, "\\$&");
}

export function commandPattern(pattern: string): RegExp {
	const source = escapeRegExp(pattern).replace(/\*/g, ".*").replace(/\?/g, ".");
	return new RegExp(`^${source}$`);
}

export function pathPattern(pattern: string, { home, ignoreCase }: MatchOptions): RegExp {
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
	return new RegExp(`${anchor}${source}$`, ignoreCase ? "i" : "");
}

/** The simple commands of a compound command line, leading `(` / `{` stripped. */
export function splitCommand(command: string): string[] {
	return command
		.split(/\n|;|&&|\|\||\||&/)
		.map((s) => s.trim().replace(/^[({]\s*/, ""))
		.filter((s) => s.length > 0);
}

/**
 * The same normalisation pi's read/write/edit tools apply before touching the
 * file system: a leading `@` (editor file mention) is dropped, `~` expands to
 * home, and relative paths resolve against the session cwd.
 */
export function normalizeToolPath(input: string, cwd: string, home: string): string {
	let p = input.startsWith("@") ? input.slice(1) : input;
	if (p === "~") p = home;
	else if (p.startsWith("~/")) p = join(home, p.slice(2));
	return isAbsolute(p) ? resolve(p) : resolve(cwd, p);
}

/**
 * The canonical form of a path whose file may not exist yet: the deepest
 * existing ancestor is resolved through `realpath`, the rest is re-appended.
 */
export function canonicalPath(path: string, realpath: (p: string) => string): string {
	const tail: string[] = [];
	let current = path;
	for (;;) {
		try {
			return tail.length === 0 ? realpath(current) : join(realpath(current), ...tail);
		} catch {
			const parent = dirname(current);
			if (parent === current) return path;
			tail.unshift(basename(current));
			current = parent;
		}
	}
}

function firstMatch(subjects: string[], patterns: string[], toRegExp: (p: string) => RegExp): string | undefined {
	return patterns.find((p) => {
		const re = toRegExp(p);
		return subjects.some((s) => re.test(s));
	});
}

/**
 * Returns the first rule that applies, deny rules before ask rules. For bash
 * `subjects` is one command line; for the file tools it is the lexical and
 * the canonical path of the target, either of which may match.
 */
export function decide(rules: Rules, tool: Tool, subjects: string[], options: MatchOptions): Verdict | undefined {
	const candidates = tool === "bash" ? subjects.flatMap(splitCommand) : subjects;
	const toRegExp = tool === "bash" ? commandPattern : (p: string) => pathPattern(p, options);
	for (const decision of ["deny", "ask"] as const) {
		const pattern = firstMatch(candidates, rules[decision]?.[tool] ?? [], toRegExp);
		if (pattern) return { decision, pattern };
	}
	return undefined;
}
