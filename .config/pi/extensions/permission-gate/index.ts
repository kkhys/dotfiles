/**
 * Enforces the Claude Code permission tiers in Pi, which runs every tool call
 * without asking. The rules are read from ~/.claude/settings.json itself rather
 * than from a translated copy, so this agent cannot drift from the source the
 * way the Codex, Devin and Cursor mirrors can.
 *
 * A guard against mistakes, not a sandbox: rules match the text of a command,
 * and a command can reach a denied file or program in ways no pattern sees.
 */

import { readFileSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import { join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { decide, parseRules, type Rule } from "./rules.ts";

const SETTINGS = join(homedir(), ".claude", "settings.json");
const AGENT_DIR = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");

// A child session can load this file twice, once as an ambient extension and
// once as a required one, and pi-subagents accepts a single registration per
// session. Shared across both copies, which are separate module instances.
const guardedSessions: Set<string> = ((globalThis as Record<symbol, unknown>)[Symbol.for("permission-gate.guarded-sessions")] ??=
	new Set<string>()) as Set<string>;

/**
 * pi-subagents runs foreground children inside this process without the
 * ambient extensions, so a child would run every command this gate denies.
 * Its required-extension registry exists for policy extensions like this one:
 * a registered path is loaded into every native child, whatever the agent
 * definition says, and a child that cannot load it is not launched.
 */
async function guardChildSessions(sessionId: string): Promise<(() => void) | undefined> {
	if (guardedSessions.has(sessionId)) return undefined;
	let api: string;
	try {
		api = createRequire(join(AGENT_DIR, "npm", "package.json")).resolve("pi-subagents/required-child-extensions");
	} catch {
		// Not installed, so there are no such children.
		return undefined;
	}
	const { registerRequiredChildExtensions } = await import(pathToFileURL(api).href);
	const registration = registerRequiredChildExtensions({
		sessionId,
		extensions: [{ id: "permission-gate", path: fileURLToPath(import.meta.url) }],
	});
	guardedSessions.add(sessionId);
	return () => {
		registration.dispose();
		guardedSessions.delete(sessionId);
	};
}

function describe(toolName: string, input: Record<string, unknown>): string {
	if (toolName === "bash") return String(input.command ?? "");
	if (typeof input.path === "string") return `${toolName} ${input.path}`;
	const args = JSON.stringify(input);
	return `${toolName} ${args.length > 400 ? `${args.slice(0, 400)}…` : args}`;
}

export default function (pi: ExtensionAPI) {
	let cache: { mtimeMs: number; rules: Rule[] } | undefined;
	let releaseChildSessions: (() => void) | undefined;
	let childGuardError: string | undefined;

	// Re-read on change so an edit to the permission lists reaches a running
	// session, as it does in Claude Code.
	const loadRules = (): Rule[] => {
		const { mtimeMs } = statSync(SETTINGS);
		if (cache?.mtimeMs !== mtimeMs) {
			cache = { mtimeMs, rules: parseRules(JSON.parse(readFileSync(SETTINGS, "utf8")).permissions) };
		}
		return cache.rules;
	};

	pi.on("session_start", async (_event, ctx) => {
		try {
			loadRules();
		} catch (error) {
			ctx.ui.notify(`permission-gate: cannot read ${SETTINGS}; every tool call will be blocked (${error})`, "error");
		}
		try {
			releaseChildSessions?.();
			childGuardError = undefined;
			releaseChildSessions = await guardChildSessions(ctx.sessionManager.getSessionId());
		} catch (error) {
			childGuardError = String(error);
			ctx.ui.notify(`permission-gate: cannot extend to subagents; the subagent tool will be blocked (${error})`, "error");
		}
	});

	pi.on("session_shutdown", () => {
		releaseChildSessions?.();
		releaseChildSessions = undefined;
	});

	pi.on("tool_call", async (event, ctx) => {
		let rules: Rule[];
		try {
			rules = loadRules();
		} catch (error) {
			// Fail closed: without the rules there is no telling a denied call from an allowed one.
			return { block: true, reason: `permission-gate: cannot read ${SETTINGS} (${error})` };
		}

		if (event.toolName === "subagent" && childGuardError) {
			return { block: true, reason: `permission-gate: subagents would run without the permission rules (${childGuardError})` };
		}

		const decision = decide(rules, event.toolName, event.input, { cwd: ctx.cwd, home: homedir() });
		if (decision.tier === "allow") return undefined;
		if (decision.tier === "deny") {
			return {
				block: true,
				reason: `Blocked by the deny rule ${decision.rule} in ${SETTINGS}. Do not retry or work around it; report it to the user.`,
			};
		}

		const cause = decision.rule ? `ask rule ${decision.rule}` : "no allow rule covers this call";
		if (!ctx.hasUI) {
			return { block: true, reason: `Needs the user's confirmation (${cause}), and this session cannot prompt.` };
		}
		const approved = await ctx.ui.confirm("Allow this tool call?", `${describe(event.toolName, event.input)}\n\n${cause}`);
		return approved ? undefined : { block: true, reason: `The user declined this call (${cause}).` };
	});
}
