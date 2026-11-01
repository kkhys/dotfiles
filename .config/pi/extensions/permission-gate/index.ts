/**
 * Permission gate: pi's counterpart to Claude Code's permissions.deny / .ask.
 *
 * Built on examples/extensions/permission-gate.ts and protected-paths.ts from
 * the pinned pi revision. The hard-coded patterns moved to
 * ~/.pi/agent/permissions.json so the rule set is declared in dotfiles.
 * deny blocks outright; ask prompts, and blocks when there is no UI.
 */

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { type ExtensionAPI, getAgentDir, isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { type Rules, type Tool, decide } from "./rules.ts";

function loadRules(): Rules {
	const file = join(getAgentDir(), "permissions.json");
	const parsed: unknown = JSON.parse(readFileSync(file, "utf8"));
	if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
		throw new Error(`${file}: expected an object with "deny" and/or "ask"`);
	}
	return parsed as Rules;
}

export default function (pi: ExtensionAPI) {
	// Read at load (and on /reload) so a missing or broken file fails the
	// extension loudly instead of silently allowing everything.
	const rules = loadRules();
	const home = homedir();

	pi.on("tool_call", async (event, ctx) => {
		let tool: Tool;
		let subject: string;
		if (isToolCallEventType("bash", event)) {
			tool = "bash";
			subject = event.input.command;
		} else if (
			isToolCallEventType("read", event) ||
			isToolCallEventType("edit", event) ||
			isToolCallEventType("write", event)
		) {
			tool = event.toolName;
			subject = resolve(ctx.cwd, event.input.path);
		} else {
			return undefined;
		}

		const verdict = decide(rules, tool, subject, home);
		if (!verdict) return undefined;

		if (verdict.decision === "deny") {
			if (ctx.hasUI) ctx.ui.notify(`Blocked ${tool} (rule "${verdict.pattern}"): ${subject}`, "warning");
			return { block: true, reason: `Blocked by permissions.json rule "${verdict.pattern}"` };
		}

		if (!ctx.hasUI) {
			return { block: true, reason: `Rule "${verdict.pattern}" needs confirmation and there is no UI` };
		}
		const allowed = await ctx.ui.confirm(`Allow ${tool}?`, `${subject}\n\nask rule: ${verdict.pattern}`);
		return allowed ? undefined : { block: true, reason: "Blocked by user" };
	});
}
