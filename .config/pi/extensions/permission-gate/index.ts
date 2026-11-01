/**
 * Permission gate: pi's counterpart to Claude Code's permissions.deny / .ask.
 *
 * Built on examples/extensions/permission-gate.ts and protected-paths.ts from
 * the pinned pi revision. The hard-coded patterns moved to
 * ~/.pi/agent/permissions.json so the rule set is declared in dotfiles.
 * deny blocks outright; ask prompts, and blocks when there is no UI.
 *
 * read rules also cover grep, find and ls: through their path argument, and
 * through any absolute deny rule rooted below that directory, so ~/.ssh
 * cannot be listed or searched. What grep matches inside files it is allowed
 * to walk is not inspected. bash is matched as text, so file paths inside
 * commands are not checked either; the deny list names the commands instead.
 */

import { readFileSync, readlinkSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { type ExtensionAPI, getAgentDir, isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { type Rules, type Tool, decide, normalizeToolPath, pathForms, withCanonicalPrefixes } from "./rules.ts";

const fs = { realpath: (p: string) => realpathSync.native(p), readlink: (p: string) => readlinkSync(p) };

function loadRules(home: string): Rules {
	const file = join(getAgentDir(), "permissions.json");
	const parsed: unknown = JSON.parse(readFileSync(file, "utf8"));
	if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
		throw new Error(`${file}: expected an object with "deny" and/or "ask"`);
	}
	return withCanonicalPrefixes(parsed as Rules, home, fs.realpath);
}

export default function (pi: ExtensionAPI) {
	const home = homedir();
	// Read at load (and on /reload) so a missing or broken file fails the
	// extension loudly instead of silently allowing everything.
	const rules = loadRules(home);
	const ignoreCase = process.platform === "darwin";

	pi.on("tool_call", async (event, ctx) => {
		let tool: Tool;
		let subjects: string[];
		let directory = false;
		if (isToolCallEventType("bash", event)) {
			tool = "bash";
			subjects = [event.input.command];
		} else if (isToolCallEventType("read", event) || isToolCallEventType("edit", event) || isToolCallEventType("write", event)) {
			tool = event.toolName;
			subjects = pathForms(normalizeToolPath(event.input.path, ctx.cwd, home), fs);
		} else if (isToolCallEventType("grep", event) || isToolCallEventType("find", event) || isToolCallEventType("ls", event)) {
			tool = "read";
			directory = true;
			subjects = pathForms(normalizeToolPath(event.input.path ?? ".", ctx.cwd, home), fs);
		} else {
			return undefined;
		}

		const verdict = decide(rules, tool, subjects, { home, ignoreCase, directory });
		if (!verdict) return undefined;
		const shown = verdict.subject === subjects[0] ? subjects[0] : `${subjects[0]} -> ${verdict.subject}`;

		if (verdict.decision === "deny") {
			if (ctx.hasUI) ctx.ui.notify(`Blocked ${event.toolName} (rule "${verdict.pattern}"): ${shown}`, "warning");
			return { block: true, reason: `Blocked by permissions.json rule "${verdict.pattern}"` };
		}

		if (!ctx.hasUI) {
			return { block: true, reason: `Rule "${verdict.pattern}" needs confirmation and there is no UI` };
		}
		const allowed = await ctx.ui.confirm(`Allow ${event.toolName}?`, `${shown}\n\nask rule: ${verdict.pattern}`);
		return allowed ? undefined : { block: true, reason: "Blocked by user" };
	});
}
