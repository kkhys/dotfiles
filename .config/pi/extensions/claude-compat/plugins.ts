// Reads Claude Code's own plugin state, so that enabling a plugin there is
// what enables it in Pi: the enabledPlugins maps of its settings files and the
// install registry it keeps beside its plugin cache.

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";

export interface Plugin {
	name: string;
	root: string;
}

export interface PluginSkill {
	plugin: string;
	name: string;
	/** `<plugin>:<name>`, the name Claude Code gives a plugin skill. */
	qualifiedName: string;
	description: string;
	file: string;
	dir: string;
	/** `disable-model-invocation`: runs on request, never offered to the model. */
	manualOnly: boolean;
}

export interface PluginMcpServer {
	plugin: string;
	name: string;
	config: Record<string, unknown>;
}

const FRONTMATTER = /^---\r?\n([\s\S]*?)\r?\n---[ \t]*(?:\r?\n|$)/;

/**
 * Top-level frontmatter keys as strings, read the way Claude Code reads them
 * rather than as strict YAML. Plugin skills carry values a YAML parser rejects
 * (`argument-hint: [a] [b]`, an unquoted description containing `: `), and
 * Pi's own loader drops such a skill entirely.
 */
export function frontmatter(text: string): Record<string, string> {
	const block = FRONTMATTER.exec(text)?.[1];
	const fields: Record<string, string> = {};
	if (block === undefined) return fields;

	const lines = block.split(/\r?\n/);
	for (let i = 0; i < lines.length; i++) {
		const match = /^([A-Za-z_][\w-]*):(?:[ \t]+(.*))?$/.exec(lines[i]);
		if (!match) continue;
		const [, key, inline = ""] = match;

		// Indented lines belong to this key: a block scalar's body, the rest
		// of a wrapped plain scalar, or a nested list this reader keeps raw.
		const continuation: string[] = [];
		while (i + 1 < lines.length && (/^\s/.test(lines[i + 1]) || lines[i + 1] === "")) continuation.push(lines[++i].trim());

		const first = inline.trim();
		if (/^[|>][+-]?$/.test(first)) {
			fields[key] = continuation.join(first.startsWith("|") ? "\n" : " ").trim();
		} else {
			fields[key] = unquote([first, ...continuation].filter(Boolean).join(" "));
		}
	}
	return fields;
}

function unquote(value: string): string {
	if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) return value.slice(1, -1).replace(/\\(["\\])/g, "$1");
	if (value.length >= 2 && value.startsWith("'") && value.endsWith("'")) return value.slice(1, -1).replace(/''/g, "'");
	return value;
}

export const stripFrontmatter = (text: string): string => text.replace(FRONTMATTER, "");

function readJson(file: string): Record<string, unknown> | undefined {
	try {
		const value = JSON.parse(readFileSync(file, "utf8"));
		return value && typeof value === "object" && !Array.isArray(value) ? value : undefined;
	} catch {
		return undefined;
	}
}

/**
 * The plugins Claude Code would load in `cwd`: enabled in the user settings or
 * in the `.claude/settings{,.local}.json` of the project, nearer files
 * overriding farther ones, and installed.
 */
export function enabledPlugins(options: { home: string; cwd: string; exclude?: string[] }): Plugin[] {
	const { home, cwd, exclude = [] } = options;

	const projectDirs: string[] = [];
	for (let dir = cwd; dir !== home; dir = dirname(dir)) {
		projectDirs.unshift(dir);
		if (dirname(dir) === dir) break;
	}
	const settingsFiles = [
		join(home, ".claude", "settings.json"),
		...projectDirs.flatMap((dir) => [join(dir, ".claude", "settings.json"), join(dir, ".claude", "settings.local.json")]),
	];

	const enabled = new Map<string, boolean>();
	for (const file of settingsFiles) {
		const flags = readJson(file)?.enabledPlugins;
		if (!flags || typeof flags !== "object") continue;
		for (const [id, on] of Object.entries(flags)) enabled.set(id, on === true);
	}

	const installed = (readJson(join(home, ".claude", "plugins", "installed_plugins.json"))?.plugins ?? {}) as Record<string, unknown>;
	const plugins = new Map<string, Plugin>();
	for (const [id, on] of enabled) {
		const name = id.split("@")[0];
		if (!on || exclude.includes(name) || plugins.has(name)) continue;
		const installs = (Array.isArray(installed[id]) ? installed[id] : []) as Array<{ scope?: string; installPath?: string }>;
		// One plugin can be installed per scope; every scope points at the same cached copy.
		const root = (installs.find((install) => install.scope === "user") ?? installs[0])?.installPath;
		if (typeof root === "string" && existsSync(root)) plugins.set(name, { name, root });
	}
	return [...plugins.values()];
}

export function pluginSkills(plugin: Plugin): PluginSkill[] {
	const skillsDir = join(plugin.root, "skills");
	let entries: string[];
	try {
		entries = readdirSync(skillsDir).sort();
	} catch {
		return [];
	}
	return entries.flatMap((entry) => {
		const dir = join(skillsDir, entry);
		const file = join(dir, "SKILL.md");
		let fields: Record<string, string>;
		try {
			fields = frontmatter(readFileSync(file, "utf8"));
		} catch {
			return [];
		}
		const description = [fields.description, fields.when_to_use].filter(Boolean).join(" ");
		if (!description) return [];
		const name = fields.name || entry;
		return [
			{
				plugin: plugin.name,
				name,
				qualifiedName: `${plugin.name}:${name}`,
				description,
				file,
				dir,
				manualOnly: fields["disable-model-invocation"] === "true",
			},
		];
	});
}

/**
 * The MCP servers a plugin ships, with the placeholders Claude Code would
 * expand already expanded. A server that needs a value this process does not
 * have is reported in `skipped` instead of being started half-configured.
 */
export function pluginMcpServers(
	plugin: Plugin,
	env: Record<string, string | undefined>,
): { servers: PluginMcpServer[]; skipped: string[] } {
	const servers: PluginMcpServer[] = [];
	const skipped: string[] = [];
	const file = readJson(join(plugin.root, ".mcp.json"));
	const entries = (file?.mcpServers && typeof file.mcpServers === "object" ? file.mcpServers : (file ?? {})) as Record<string, unknown>;

	for (const [name, raw] of Object.entries(entries)) {
		if (!raw || typeof raw !== "object" || Array.isArray(raw)) continue;
		const missing = new Set<string>();
		const expand = (value: unknown): unknown => {
			if (typeof value === "string") {
				return value.replace(/\$\{([^}:]+)(?::-([^}]*))?\}/g, (_, variable: string, fallback?: string) => {
					if (variable === "CLAUDE_PLUGIN_ROOT") return plugin.root;
					const resolved = env[variable] ?? fallback;
					if (resolved === undefined) missing.add(variable);
					return resolved ?? "";
				});
			}
			if (Array.isArray(value)) return value.map(expand);
			if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([key, item]) => [key, expand(item)]));
			return value;
		};
		const config = expand(raw) as Record<string, unknown>;
		if (missing.size > 0) skipped.push(`${plugin.name}:${name} (needs ${[...missing].join(", ")})`);
		else servers.push({ plugin: plugin.name, name, config });
	}
	return { servers, skipped };
}
