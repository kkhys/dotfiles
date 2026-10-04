// The ChatGPT backend reports plan usage two ways, and which one arrives
// depends on the transport: `x-codex-*` response headers over HTTP, a
// `codex.rate_limits` stream event over WebSocket. Field names follow the
// Codex CLI (codex-rs/codex-api/src/rate_limits.rs).

export interface Window {
	usedPercent: number;
	windowMinutes?: number;
}

export interface Limits {
	primary?: Window;
	secondary?: Window;
}

const finite = (value: unknown): number | undefined => {
	const number = typeof value === "string" && value.trim() !== "" ? Number(value) : value;
	return typeof number === "number" && Number.isFinite(number) ? number : undefined;
};

function window(usedPercent: unknown, windowMinutes: unknown, resetAt: unknown): Window | undefined {
	const used = finite(usedPercent);
	if (used === undefined) return undefined;
	const minutes = finite(windowMinutes);
	// The backend sends an all-zero window for a limit that does not apply.
	if (used === 0 && !minutes && finite(resetAt) === undefined) return undefined;
	return minutes ? { usedPercent: used, windowMinutes: minutes } : { usedPercent: used };
}

const limits = (primary: Window | undefined, secondary: Window | undefined): Limits | undefined =>
	primary || secondary ? { ...(primary && { primary }), ...(secondary && { secondary }) } : undefined;

export function fromHeaders(headers: Record<string, string>): Limits | undefined {
	const get = (name: string) => Object.entries(headers).find(([key]) => key.toLowerCase() === name)?.[1];
	const read = (slot: string) =>
		window(get(`x-codex-${slot}-used-percent`), get(`x-codex-${slot}-window-minutes`), get(`x-codex-${slot}-reset-at`));
	return limits(read("primary"), read("secondary"));
}

export function fromEvent(data: unknown): Limits | undefined {
	const event = data as { type?: unknown; rate_limits?: Record<string, Record<string, unknown> | null> | null } | null;
	if (event?.type !== "codex.rate_limits" || !event.rate_limits) return undefined;
	const read = (slot: string) => {
		const entry = event.rate_limits?.[slot];
		return entry ? window(entry.used_percent, entry.window_minutes, entry.reset_at) : undefined;
	};
	return limits(read("primary"), read("secondary"));
}

function label(minutes: number | undefined, fallback: string): string {
	if (!minutes) return fallback;
	if (minutes % 1440 === 0) return `${minutes / 1440}d`;
	if (minutes % 60 === 0) return `${minutes / 60}h`;
	return `${minutes}m`;
}

/** `5h 42% · 7d 86%`, the windows named by their length as Codex's status line does. */
export function format({ primary, secondary }: Limits): string {
	const part = (entry: Window | undefined, fallback: string) =>
		entry ? [`${label(entry.windowMinutes, fallback)} ${Math.round(entry.usedPercent)}%`] : [];
	return [...part(primary, "primary"), ...part(secondary, "secondary")].join(" · ");
}
