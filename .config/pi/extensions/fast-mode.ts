/**
 * OpenAI's priority service tier for the ChatGPT-subscription models: what
 * `service_tier = "fast"` is in Codex. Responses come sooner and the plan's
 * quota drains faster, so /fast turns it off for the rest of the session.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	let enabled = true;
	const show = (ctx: ExtensionContext) => ctx.ui.setStatus("fast", enabled ? "fast" : undefined);

	pi.on("session_start", (_event, ctx) => show(ctx));

	pi.registerCommand("fast", {
		description: "Toggle the priority service tier",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			show(ctx);
			ctx.ui.notify(`Fast mode ${enabled ? "on" : "off"}`, "info");
		},
	});

	pi.on("before_provider_request", (event, ctx) => {
		const { payload } = event;
		// Other providers reject or bill the field differently.
		if (!enabled || ctx.model?.provider !== "openai-codex") return undefined;
		if (!payload || typeof payload !== "object" || Array.isArray(payload)) return undefined;
		return { ...payload, service_tier: "priority" };
	});
}
