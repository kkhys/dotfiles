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
 * A command line is matched whole and also split at `;`, `&&`, `||`, `|`,
 * `&` and newlines with every segment matched, so `ls; rm -rf x` is caught by
 * the rm rule. Quotes, `$(...)` and backticks are not parsed: a separator
 * inside a string splits too, which can only add matches, and a command
 * hidden inside a substitution is not seen.
 */

import { basename, dirname, isAbsolute, join, resolve } from "node:path";

export type Tool = "bash" | "read" | "edit" | "write";
export type Decision = "deny" | "ask";

export type Rules = Partial<Record<Decision, Partial<Record<Tool, string[]>>>>;

export interface Verdict {
	decision: Decision;
	pattern: string;
	subject: string;
}

export interface MatchOptions {
	home: string;
	/** macOS file systems ignore case, so `.env` must also catch `.ENV`. */
	ignoreCase?: boolean;
	/** The subject is a directory the tool will walk: a rule under it applies too. */
	directory?: boolean;
}

export interface FsLike {
	realpath: (p: string) => string;
	/** Throws when `p` is not a symlink. */
	readlink: (p: string) => string;
}

function escapeRegExp(s: string): string {
	return s.replace(/[.+^${}()|[\]\\]/g, "\\$&");
}

export function expandPathPattern(pattern: string, home: string): string {
	if (pattern.startsWith("~/")) return `${home}/${pattern.slice(2)}`;
	if (pattern.startsWith("//")) return pattern.slice(1);
	return pattern;
}

export function commandPattern(pattern: string): RegExp {
	const source = escapeRegExp(pattern).replace(/\*/g, ".*").replace(/\?/g, ".");
	return new RegExp(`^${source}$`);
}

export function pathPattern(pattern: string, { home, ignoreCase }: MatchOptions): RegExp {
	const expanded = expandPathPattern(pattern, home);
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

/** The directory an absolute pattern names before its first wildcard, or undefined. */
export function literalDirectory(pattern: string, home: string): string | undefined {
	const expanded = expandPathPattern(pattern, home);
	if (!expanded.startsWith("/")) return undefined;
	const wildcard = expanded.search(/[*?]/);
	const literal = wildcard === -1 ? expanded : expanded.slice(0, wildcard);
	return literal.endsWith("/") ? literal.slice(0, -1) : dirname(literal);
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
 * Every form a path takes on the way to the file system: the path itself,
 * each symlink hop (dangling links included, since a write creates the
 * target) and the canonical result. Components that do not exist yet are
 * re-appended to the deepest existing ancestor. Rules are matched against
 * all of them, so neither a link into ~/.ssh nor a link out of it hides.
 */
export function pathForms(path: string, fs: FsLike, maxHops = 32): string[] {
	const forms = [path];
	let current = path;
	const tail: string[] = [];
	for (let hop = 0; hop < maxHops; hop++) {
		try {
			forms.push(join(fs.realpath(current), ...tail));
			break;
		} catch {
			// `current` is missing or dangling: follow it if it is a link, else go up.
		}
		let target: string | undefined;
		try {
			target = fs.readlink(current);
		} catch {
			target = undefined;
		}
		if (target !== undefined) {
			// A relative target is relative to where the link really lives.
			const parent = canonical(dirname(current), fs, maxHops - hop - 1);
			current = isAbsolute(target) ? target : resolve(parent, target);
			forms.push(join(current, ...tail));
			continue;
		}
		const parent = dirname(current);
		if (parent === current) break;
		tail.unshift(basename(current));
		current = parent;
	}
	return [...new Set(forms)];
}

/** The last form of a path: its canonical path, or the path itself when nothing resolves. */
export function canonical(path: string, fs: FsLike, maxHops = 32): string {
	const forms = pathForms(path, fs, maxHops);
	return forms[forms.length - 1];
}

/**
 * Rules whose absolute or `~` prefix is itself behind a symlink (nix-darwin's
 * /run is one) get a twin written against the canonical prefix.
 */
export function withCanonicalPrefixes(rules: Rules, home: string, realpath: (p: string) => string): Rules {
	const out: Rules = {};
	for (const decision of ["deny", "ask"] as const) {
		const section = rules[decision];
		if (!section) continue;
		out[decision] = {};
		for (const tool of ["bash", "read", "edit", "write"] as const) {
			const patterns = section[tool];
			if (!patterns) continue;
			const expanded: string[] = [];
			for (const pattern of patterns) {
				expanded.push(pattern);
				if (tool === "bash") continue;
				const dir = literalDirectory(pattern, home);
				if (dir === undefined) continue;
				try {
					const canonical = realpath(dir);
					if (canonical !== dir) expanded.push(`/${canonical}${expandPathPattern(pattern, home).slice(dir.length)}`);
				} catch {
					// Prefix does not exist on this machine; the literal rule stays.
				}
			}
			out[decision][tool] = expanded;
		}
	}
	return out;
}

function isSameOrBelow(path: string, directory: string, ignoreCase?: boolean): boolean {
	const fold = (s: string) => (ignoreCase ? s.toLowerCase() : s);
	const prefix = directory.endsWith("/") ? directory : `${directory}/`;
	return fold(path) === fold(directory) || fold(path).startsWith(fold(prefix));
}

function firstMatch(
	subjects: string[],
	patterns: string[],
	toRegExp: (p: string) => RegExp,
): { pattern: string; subject: string } | undefined {
	for (const pattern of patterns) {
		const re = toRegExp(pattern);
		const subject = subjects.find((s) => re.test(s));
		if (subject !== undefined) return { pattern, subject };
	}
	return undefined;
}

/**
 * Returns the first rule that applies, deny rules before ask rules. For bash
 * `subjects` is one command line; for the file tools it is every form of the
 * target path (see pathForms), any of which may match. With `directory` set,
 * a rule rooted below the subject also applies, since walking the directory
 * reaches it.
 */
export function decide(rules: Rules, tool: Tool, subjects: string[], options: MatchOptions): Verdict | undefined {
	const candidates = tool === "bash" ? [...subjects, ...subjects.flatMap(splitCommand)] : subjects;
	const toRegExp = tool === "bash" ? commandPattern : (p: string) => pathPattern(p, options);
	for (const decision of ["deny", "ask"] as const) {
		const patterns = rules[decision]?.[tool] ?? [];
		const hit = firstMatch(candidates, patterns, toRegExp);
		if (hit) return { decision, ...hit };
		if (tool !== "bash" && options.directory) {
			for (const pattern of patterns) {
				const dir = literalDirectory(pattern, options.home);
				if (dir === undefined) continue;
				const subject = subjects.find((s) => isSameOrBelow(dir, s, options.ignoreCase));
				if (subject !== undefined) return { decision, pattern, subject };
			}
		}
	}
	return undefined;
}
