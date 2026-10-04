/**
 * The sounds the base Claude Code plugin plays from its Stop and Notification
 * hooks: one when a run finishes, another when Pi is waiting on an answer.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const DONE = "/System/Library/Sounds/Glass.aiff";
const ATTENTION = "/System/Library/Sounds/Hero.aiff";

export default function (pi: ExtensionAPI) {
	const play = (sound: string) => {
		// afplay and these files exist only on macOS; elsewhere stay silent.
		void pi.exec("afplay", [sound], { timeout: 10_000 }).catch(() => {});
	};

	// Background subagent sessions load this extension too. Only the session
	// on screen should make noise, or every delegated task would chime.
	pi.on("agent_settled", (_event, ctx) => {
		if (ctx.mode === "tui") play(DONE);
	});
	pi.on("ui_prompt_start", (_event, ctx) => {
		if (ctx.mode === "tui") play(ATTENTION);
	});
}
