// Run with: node --test .config/pi/extensions/

import assert from "node:assert/strict";
import { test } from "node:test";

import { format, fromEvent, fromHeaders } from "./limits.ts";

test("both windows are read from response headers", () => {
	const limits = fromHeaders({
		"content-type": "text/event-stream",
		"x-codex-primary-used-percent": "12.5",
		"x-codex-primary-window-minutes": "300",
		"x-codex-secondary-used-percent": "40.0",
		"x-codex-secondary-window-minutes": "10080",
	});
	assert.deepEqual(limits, {
		primary: { usedPercent: 12.5, windowMinutes: 300 },
		secondary: { usedPercent: 40, windowMinutes: 10080 },
	});
	assert.equal(format(limits!), "5h 13% · 7d 40%");
});

test("header names match whatever their case", () => {
	assert.deepEqual(fromHeaders({ "X-Codex-Primary-Used-Percent": "100.0" }), { primary: { usedPercent: 100 } });
});

test("a response without the headers reports nothing", () => {
	assert.equal(fromHeaders({ "content-type": "application/json" }), undefined);
	assert.equal(fromHeaders({ "x-codex-primary-used-percent": "not a number" }), undefined);
});

test("an all-zero window is a limit that does not apply", () => {
	assert.deepEqual(
		fromHeaders({
			"x-codex-primary-used-percent": "37",
			"x-codex-primary-window-minutes": "300",
			"x-codex-secondary-used-percent": "0",
			"x-codex-secondary-window-minutes": "0",
		}),
		{ primary: { usedPercent: 37, windowMinutes: 300 } },
	);
	// Zero used inside a real window is a report, not an absence.
	assert.deepEqual(fromHeaders({ "x-codex-primary-used-percent": "0", "x-codex-primary-reset-at": "1790000000" }), {
		primary: { usedPercent: 0 },
	});
});

test("the stream event carries the same windows", () => {
	const limits = fromEvent({
		type: "codex.rate_limits",
		plan_type: "plus",
		rate_limits: {
			primary: { used_percent: 87.5, window_minutes: 300, reset_at: 1790000000 },
			secondary: null,
		},
	});
	assert.deepEqual(limits, { primary: { usedPercent: 87.5, windowMinutes: 300 } });
	assert.equal(format(limits!), "5h 88%");
});

test("other stream events are ignored", () => {
	assert.equal(fromEvent({ type: "response.output_text.delta", delta: "hi" }), undefined);
	assert.equal(fromEvent({ type: "codex.rate_limits" }), undefined);
	assert.equal(fromEvent(null), undefined);
	assert.equal(fromEvent("codex.rate_limits"), undefined);
});

test("a window is named by its length, or by its slot when the length is unknown", () => {
	assert.equal(format({ primary: { usedPercent: 5, windowMinutes: 15 } }), "15m 5%");
	assert.equal(format({ primary: { usedPercent: 5, windowMinutes: 60 } }), "1h 5%");
	assert.equal(format({ primary: { usedPercent: 5 }, secondary: { usedPercent: 9 } }), "primary 5% · secondary 9%");
});
