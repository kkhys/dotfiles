/**
 * Status line - a one-line footer in the style of Claude Code's statusLine:
 *
 *   Opus 5.5 high | main | 10.2K (20%) | cache hit 94% | $0.42 | <extension statuses>
 *
 * Replaces pi's default two-line footer (cwd + token stats) at session start.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

// Matches editorPaddingX in settings.json so the line starts under the editor text.
const PADDING_X = 1;

function formatTokens(count: number): string {
	if (count < 1000) return `${count}`;
	return `${(count / 1000).toFixed(1)}K`.replace(".0K", "K");
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
			const dim = (text: string) => theme.fg("dim", text);
			// Same thresholds as the Claude Code statusline: green, then yellow from 70%, red from 90%.
			const usageColor = (percent: number) =>
				theme.fg(percent >= 90 ? "error" : percent >= 70 ? "warning" : "success", `${percent}%`);
			const cacheColor = (percent: number) =>
				theme.fg(percent >= 80 ? "success" : percent >= 50 ? "warning" : "error", `${percent}%`);

			return {
				dispose: unsubscribe,
				invalidate() {},
				render(width: number): string[] {
					const parts: string[] = [];

					const model = ctx.model;
					if (model) {
						const name = model.name.replace(/^Claude /, "");
						const level = model.reasoning ? ` ${ctx.thinkingLevel ?? "off"}` : "";
						parts.push(dim(`${name}${level}`));
					}

					const branch = footerData.getGitBranch();
					if (branch) parts.push(dim(branch));

					const usage = ctx.getContextUsage();
					if (usage?.tokens && usage.percent != null) {
						parts.push(`${dim(formatTokens(usage.tokens))} ${dim("(")}${usageColor(Math.round(usage.percent))}${dim(")")}`);
					} else {
						parts.push(dim("--"));
					}

					let cost = 0;
					let latest: AssistantMessage | undefined;
					for (const entry of ctx.sessionManager.getBranch()) {
						if (entry.type === "message" && entry.message.role === "assistant") {
							latest = entry.message as AssistantMessage;
							cost += latest.usage.cost.total;
						}
					}
					if (latest) {
						const prompt = latest.usage.input + latest.usage.cacheRead + latest.usage.cacheWrite;
						if (prompt > 0) {
							const hit = Math.round((latest.usage.cacheRead / prompt) * 100);
							parts.push(`${dim("cache hit ")}${cacheColor(hit)}`);
						}
					}
					if (cost > 0) {
						// OAuth means a subscription pays for the tokens, so the figure is only what the API would cost.
						const sub = model && ctx.modelRegistry.isUsingOAuth(model) ? " (sub)" : "";
						parts.push(dim(`$${cost.toFixed(2)}${sub}`));
					}

					for (const [, text] of [...footerData.getExtensionStatuses()].sort(([a], [b]) => a.localeCompare(b))) {
						parts.push(text);
					}

					const line = " ".repeat(PADDING_X) + parts.join(dim(" | "));
					return [truncateToWidth(line, width, dim("..."))];
				},
			};
		});
	});
}
