import { isAbsolute, resolve } from "node:path";

export type Tier = "deny" | "ask" | "allow";

export interface Rule {
	tier: Tier;
	/** Claude Code tool name: `Bash`, `Read`, `Edit`, `Write`, or an `mcp__` glob. */
	tool: string;
	specifier?: string;
	/** The entry as written in settings.json, quoted back in messages. */
	source: string;
}

export interface Decision {
	tier: Tier;
	rule?: string;
}

export interface Env {
	cwd: string;
	home: string;
}

const TIERS: Tier[] = ["deny", "ask", "allow"];
const READ_TOOLS = new Set(["read", "grep", "find", "ls"]);
const EDIT_TOOLS = new Set(["edit", "write"]);
const SHELLS = new Set(["sh", "bash", "zsh", "dash"]);
// Prefixes that run the command that follows them, so a rule written for that
// command still has to match.
const WRAPPERS = new Set(["sudo", "command", "builtin", "exec", "nohup", "time", "nice", "env", "timeout", "caffeinate"]);

export function parseRules(permissions: unknown): Rule[] {
	const lists = (permissions ?? {}) as Partial<Record<Tier, unknown>>;
	return TIERS.flatMap((tier) => {
		const entries = lists[tier];
		if (!Array.isArray(entries)) return [];
		return entries.filter((entry): entry is string => typeof entry === "string").map((source) => {
			const open = source.indexOf("(");
			if (open === -1 || !source.endsWith(")")) return { tier, tool: source, source };
			return { tier, tool: source.slice(0, open), specifier: source.slice(open + 1, -1), source };
		});
	});
}

/**
 * Resolve a Pi tool call against Claude Code permission rules: deny, then ask,
 * then allow. A call no rule covers needs confirmation, as in Claude Code's
 * default mode, except for extension tools, which have no Claude Code name a
 * rule could be written against.
 */
export function decide(rules: Rule[], toolName: string, input: Record<string, unknown>, env: Env): Decision {
	const matcher = matcherFor(toolName, input, env);
	if (!matcher) return { tier: "allow" };
	for (const tier of TIERS) {
		const rule = rules.find((candidate) => candidate.tier === tier && matcher(candidate));
		if (rule) return { tier, rule: rule.source };
	}
	return { tier: "ask" };
}

type Matcher = (rule: Rule) => boolean;

function matcherFor(toolName: string, input: Record<string, unknown>, env: Env): Matcher | undefined {
	if (toolName === "bash") {
		const commands = commandForms(String(input.command ?? ""));
		return (rule) => {
			if (rule.tool !== "Bash") return false;
			if (rule.specifier === undefined) return true;
			const pattern = bashPattern(rule.specifier);
			const hit = (forms: string[]) => forms.some((form) => pattern.test(form));
			// A restriction applies if any part of the line trips it; a grant
			// only if every part is covered, or `allowed && anything` would pass.
			return rule.tier === "allow" ? commands.every(hit) : commands.some(hit);
		};
	}
	if (READ_TOOLS.has(toolName) || EDIT_TOOLS.has(toolName)) {
		const tools = READ_TOOLS.has(toolName) ? ["Read"] : ["Edit", "Write"];
		const raw = typeof input.path === "string" && input.path !== "" ? input.path : ".";
		const expanded = raw === "~" || raw.startsWith("~/") ? env.home + raw.slice(1) : raw;
		const path = isAbsolute(expanded) ? resolve(expanded) : resolve(env.cwd, expanded);
		return (rule) => tools.includes(rule.tool) && (rule.specifier === undefined || pathPattern(rule.specifier, env.home).test(path));
	}
	if (toolName.startsWith("mcp__")) {
		return (rule) => rule.tool.startsWith("mcp__") && mcpPattern(rule.tool).test(toolName);
	}
	return undefined;
}

const escapeRegExp = (text: string) => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

function bashPattern(specifier: string): RegExp {
	// `cmd:*` is Claude Code's prefix form: the command alone or followed by arguments.
	if (specifier.endsWith(":*")) return new RegExp(`^${escapeRegExp(specifier.slice(0, -2))}(?:\\s.*)?$`, "s");
	// A trailing ` *` also matches the bare command, so `ls *` covers `ls`.
	const bare = specifier.endsWith(" *");
	const body = (bare ? specifier.slice(0, -2) : specifier).split("*").map(escapeRegExp).join(".*");
	return new RegExp(`^${body}${bare ? "(?:\\s.*)?" : ""}$`, "s");
}

function pathPattern(specifier: string, home: string): RegExp {
	// gitignore-style: `~/` and `/` anchor the pattern, anything else matches at any depth.
	let anchor = "^(?:.*/)?";
	let glob = specifier;
	if (glob.startsWith("~/")) {
		anchor = `^${escapeRegExp(home)}/`;
		glob = glob.slice(2);
	} else if (glob.startsWith("/")) {
		anchor = "^/";
		glob = glob.replace(/^\/+/, "");
	} else {
		glob = glob.replace(/^\.\//, "").replace(/^(?:\*\*\/)+/, "");
	}
	let body = "";
	for (let i = 0; i < glob.length; i++) {
		if (glob.startsWith("**/", i)) {
			body += "(?:.*/)?";
			i += 2;
		} else if (glob.startsWith("**", i)) {
			body += ".*";
			i += 1;
		} else if (glob[i] === "*") {
			body += "[^/]*";
		} else if (glob[i] === "?") {
			body += "[^/]";
		} else {
			body += escapeRegExp(glob[i]);
		}
	}
	return new RegExp(`${anchor}${body}$`);
}

function mcpPattern(tool: string): RegExp {
	// Claude Code names a plugin's server `plugin_<plugin>_<server>`; Pi uses
	// the bare server name and replaces every character outside [A-Za-z0-9_].
	const name = tool.replace(/^mcp__plugin_[^_]+_/, "mcp__").replace(/[^A-Za-z0-9_*]/g, "_");
	const body = name.split("*").map(escapeRegExp).join(".*");
	// `mcp__server` without a tool part covers every tool of that server.
	return new RegExp(`^${body}${name.slice(5).includes("__") ? "" : "(?:__.*)?"}$`);
}

/**
 * Every simple command a shell line runs, each as the list of spellings a rule
 * may match: as written, with quoting removed, and with leading environment
 * assignments and wrapper commands dropped.
 */
export function commandForms(line: string): string[][] {
	const forms: string[][] = [];
	const whole = line.trim();
	const segments = splitCommands(line);
	// Rules written against a pipeline as a whole still match.
	if (segments.length > 1 && whole) forms.push([whole]);
	for (const segment of segments) {
		const words = tokenize(segment);
		const spellings = new Set([segment, words.join(" ")]);
		let rest = words;
		for (;;) {
			if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(rest[0] ?? "")) {
				rest = rest.slice(1);
			} else if (WRAPPERS.has(rest[0] ?? "")) {
				rest = rest.slice(1);
				while (/^(?:-|\d)/.test(rest[0] ?? "")) rest = rest.slice(1);
			} else {
				break;
			}
			if (rest.length > 0) spellings.add(rest.join(" "));
		}
		forms.push([...spellings]);

		// `sh -c '<script>'` and `eval <script>` hide the commands a rule is about.
		const flag = SHELLS.has(rest[0] ?? "") ? rest.findIndex((word) => /^-[A-Za-z]*c[A-Za-z]*$/.test(word)) : -1;
		const script = flag !== -1 ? rest[flag + 1] : rest[0] === "eval" ? rest.slice(1).join(" ") : undefined;
		if (script) forms.push(...commandForms(script));
	}
	return forms;
}

function splitCommands(line: string): string[] {
	const segments: string[] = [];
	// Quote state of each enclosing `$(…)` or `(…)`, restored when it closes.
	const outer: Array<string | undefined> = [];
	let quote: string | undefined;
	let current = "";
	const flush = () => {
		if (current.trim()) segments.push(current.trim());
		current = "";
	};
	for (let i = 0; i < line.length; i++) {
		const char = line[i];
		if (quote === "'") {
			current += char;
			if (char === "'") quote = undefined;
		} else if (char === "\\" && i + 1 < line.length) {
			current += char + line[++i];
		} else if (char === "`") {
			flush();
		} else if (char === "$" && line[i + 1] === "(") {
			flush();
			outer.push(quote);
			quote = undefined;
			i++;
		} else if (quote === '"') {
			current += char;
			if (char === '"') quote = undefined;
		} else if (char === "'" || char === '"') {
			quote = char;
			current += char;
		} else if (char === "(") {
			flush();
			outer.push(undefined);
		} else if (char === ")" && outer.length > 0) {
			flush();
			quote = outer.pop();
		} else if (char === ";" || char === "\n" || char === "|" || char === "&") {
			flush();
		} else {
			current += char;
		}
	}
	flush();
	return segments;
}

function tokenize(segment: string): string[] {
	const words: string[] = [];
	let quote: string | undefined;
	let current: string | undefined;
	for (let i = 0; i < segment.length; i++) {
		const char = segment[i];
		if (quote) {
			if (char === quote) quote = undefined;
			else if (char === "\\" && quote === '"' && i + 1 < segment.length) current += segment[++i];
			else current += char;
		} else if (char === "'" || char === '"') {
			quote = char;
			current ??= "";
		} else if (char === "\\" && i + 1 < segment.length) {
			current = (current ?? "") + segment[++i];
		} else if (/\s/.test(char)) {
			if (current !== undefined) words.push(current);
			current = undefined;
		} else {
			current = (current ?? "") + char;
		}
	}
	if (current !== undefined) words.push(current);
	return words;
}
