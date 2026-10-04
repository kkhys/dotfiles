/**
 * Shows how much of the ChatGPT plan's rate-limit windows is used, the way the
 * Codex and Claude Code status lines do. Pi's footer only knows tokens and
 * list-price cost, which say nothing about a subscription's remaining quota.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

import { format, fromEvent, fromHeaders, type Limits } from "./limits.ts";

export default function (pi: ExtensionAPI) {
	const show = (limits: Limits | undefined, ctx: ExtensionContext) => {
		// No report in this response is not "no usage": keep the last one.
		if (limits) ctx.ui.setStatus("usage", format(limits));
	};

	pi.on("after_provider_response", (event, ctx) => show(fromHeaders(event.headers), ctx));
	pi.on("provider_stream_event", (event, ctx) => {
		if (event.provider === "openai-codex") show(fromEvent(event.data), ctx);
	});
}
