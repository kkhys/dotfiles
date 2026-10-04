/**
 * Claude Code conventions Pi does not share: the command spellings typed out
 * of habit, the frontmatter field the shared skills put their triggers in, and
 * plugins. Pi has packages but no plugin scope, so the skills and MCP servers
 * of whatever is enabled in Claude Code are loaded from here instead.
 */

import { readFileSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

import { type ExtensionAPI, type ExtensionContext, parseFrontmatter } from "@earendil-works/pi-coding-agent";

import { enabledPlugins, type PluginSkill, pluginMcpServers, pluginSkills, stripFrontmatter } from "./plugins.ts";

const AGENT_DIR = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");

// Pi rejects a longer description on a skill it loads itself. Every listed
// description sits in the system prompt, so plugin skills get the same cap.
const MAX_DESCRIPTION = 1024;
const clip = (text: string) => (text.length > MAX_DESCRIPTION ? `${text.slice(0, MAX_DESCRIPTION - 1)}…` : text);

// Pi treats server names that differ only in `-` and `_` as one server.
const serverKey = (name: string) => name.replace(/-/g, "_");

// Marketplace skills and plugin commands are linked in by bare name, so the
// plugin one belongs to is only visible in the path the link resolves to.
function isFromPlugin(path: string, plugin: string): boolean {
	try {
		return realpathSync(path).includes(`/plugins/${plugin}/`);
	} catch {
		return false;
	}
}

// The block Pi builds for /skill:<name>, so both kinds reach the model alike.
function expand(skill: PluginSkill, args: string): string {
	const body = stripFrontmatter(readFileSync(skill.file, "utf8")).trim();
	const block = `<skill name="${skill.qualifiedName}" location="${skill.file}">\nReferences are relative to ${skill.dir}.\n\n${body}\n</skill>`;
	return args ? `${block}\n\n${args}` : block;
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("clear", {
		description: "Start a new session",
		handler: async (_args, ctx) => {
			await ctx.newSession();
		},
	});

	// Plugin skills Pi did not load itself, under their Claude Code names.
	let pluginOnly: PluginSkill[] = [];

	const loadPlugins = (ctx: ExtensionContext) => {
		const settings = pi.getSettings() as { claudePlugins?: { exclude?: string[] } };
		const plugins = enabledPlugins({ home: homedir(), cwd: ctx.cwd, exclude: settings.claudePlugins?.exclude });

		// A plugin whose skills are linked into ~/.agents/skills from its
		// working tree is already loaded, and that tree is the newer copy:
		// the installed one would list every skill twice, plus any since
		// renamed or removed.
		const native = pi.getCommands().filter((command) => command.source === "skill");
		pluginOnly = plugins
			.filter((plugin) => !native.some((command) => isFromPlugin(command.sourceInfo.path, plugin.name)))
			.flatMap(pluginSkills);

		// A server Pi's own mcp.json already defines wins there; registering
		// it again would only add an overridden entry to /mcp.
		const taken = new Set(
			[join(AGENT_DIR, "mcp.json"), join(ctx.cwd, ".pi", "mcp.json")].flatMap((file) => {
				try {
					return Object.keys(JSON.parse(readFileSync(file, "utf8")).mcpServers ?? {}).map(serverKey);
				} catch {
					return [];
				}
			}),
		);
		const problems: string[] = [];
		for (const plugin of plugins) {
			const { servers, skipped } = pluginMcpServers(plugin, process.env);
			problems.push(...skipped);
			for (const server of servers) {
				if (taken.has(serverKey(server.name))) continue;
				taken.add(serverKey(server.name));
				try {
					pi.registerMcpServer(server.name, server.config as Parameters<ExtensionAPI["registerMcpServer"]>[1]);
				} catch (error) {
					problems.push(`${server.plugin}:${server.name} (${error instanceof Error ? error.message : error})`);
				}
			}
		}
		if (problems.length > 0) ctx.ui.notify(`claude-compat: plugin MCP servers not loaded: ${problems.join("; ")}`, "warning");
	};

	pi.on("session_start", (_event, ctx) => {
		try {
			loadPlugins(ctx);
		} catch (error) {
			ctx.ui.notify(`claude-compat: Claude Code plugins not loaded (${error})`, "warning");
		}
	});

	// Claude Code runs a skill as /<name> or /<plugin>:<name> and a plugin
	// command as /<plugin>:<name>; Pi as /skill:<name> and /<name>.
	pi.on("input", (event) => {
		const match = /^\/(?:([\w-]+):)?([\w-]+)(?=\s|$)/.exec(event.text);
		if (!match) return { action: "continue" };
		const [typed, plugin, name] = match;
		if (plugin === "skill") return { action: "continue" };

		const commands = pi.getCommands();
		// A command of that exact spelling is what the user asked for.
		if (commands.some((command) => command.name === typed.slice(1))) return { action: "continue" };
		const rest = event.text.slice(typed.length);
		const target =
			commands.find((command) => command.source === "prompt" && command.name === name) ??
			commands.find((command) => command.name === `skill:${name}`);
		// Another plugin can ship the same name with different rules; running
		// this one under its name would be silently wrong.
		if (target && (!plugin || isFromPlugin(target.sourceInfo.path, plugin))) {
			return { action: "transform", text: `/${target.name}${rest}`, images: event.images };
		}

		// Expanded here rather than registered as commands: a command handler
		// can only start a turn on the side, which print mode does not wait
		// for. A bare name runs when it names one plugin skill.
		const candidates = pluginOnly.filter((skill) => skill.name === name && (!plugin || skill.plugin === plugin));
		if (candidates.length === 1) return { action: "transform", text: expand(candidates[0], rest.trim()), images: event.images };
		return { action: "continue" };
	});

	// Claude Code routes on `description` plus `when_to_use`, and the shared
	// skills keep their trigger phrases in the latter. Pi lists `description`
	// alone, which leaves those skills reachable only by explicit command.
	const triggers = new Map<string, string>();
	const whenToUse = (skillFile: string): string => {
		let text = triggers.get(skillFile);
		if (text === undefined) {
			try {
				const value = parseFrontmatter(readFileSync(skillFile, "utf8")).frontmatter.when_to_use;
				text = typeof value === "string" ? value.trim() : "";
			} catch {
				text = "";
			}
			triggers.set(skillFile, text);
		}
		return text;
	};

	pi.on("before_agent_start", (event) => {
		// Copies: the listed skills outlive this prompt, and appending in
		// place would repeat the text on every one that follows.
		const listed = event.systemPromptOptions.skills.map((skill) => {
			const extra = whenToUse(skill.filePath);
			return extra ? { ...skill, description: clip(`${skill.description} ${extra}`) } : skill;
		});
		const names = new Set(listed.map((skill) => skill.name));
		for (const skill of pluginOnly) {
			if (skill.manualOnly || names.has(skill.qualifiedName)) continue;
			listed.push({
				name: skill.qualifiedName,
				description: clip(skill.description),
				filePath: skill.file,
				baseDir: skill.dir,
				sourceInfo: { path: skill.file, source: `claude-plugin:${skill.plugin}`, scope: "user", origin: "top-level" },
				disableModelInvocation: false,
			});
		}
		event.systemPromptOptions.skills = listed;
	});
}
