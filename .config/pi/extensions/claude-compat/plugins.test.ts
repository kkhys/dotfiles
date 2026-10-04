// Run with: node --test .config/pi/extensions/

import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";

import { enabledPlugins, frontmatter, pluginMcpServers, pluginSkills, stripFrontmatter } from "./plugins.ts";

function tree(files: Record<string, string>): string {
	const root = mkdtempSync(join(tmpdir(), "claude-compat-"));
	for (const [path, content] of Object.entries(files)) {
		mkdirSync(dirname(join(root, path)), { recursive: true });
		writeFileSync(join(root, path), content);
	}
	return root;
}

test("frontmatter a YAML parser rejects is still read", () => {
	const fields = frontmatter(
		[
			"---",
			"name: creating-pr",
			"description: Creates a draft PR following the title convention: `[main][ID] type: text`. Use when opening a PR.",
			"argument-hint: [task-url] [base-branch]",
			"---",
			"body",
		].join("\n"),
	);
	assert.equal(fields.name, "creating-pr");
	assert.equal(fields.description, "Creates a draft PR following the title convention: `[main][ID] type: text`. Use when opening a PR.");
	assert.equal(fields["argument-hint"], "[task-url] [base-branch]");
});

test("block scalars, wrapped values and quotes read as their text", () => {
	const fields = frontmatter(
		[
			"---",
			'description: "Says \\"hi\\" back"',
			"when_to_use: >-",
			"  Always consult when committing —",
			'  "commit", "コミット".',
			"notes: |",
			"  line one",
			"  line two",
			"wrapped: first part",
			"  second part",
			"allowed-tools:",
			"  - Bash(git:*)",
			"  - Read",
			"disable-model-invocation: true",
			"---",
		].join("\n"),
	);
	assert.equal(fields.description, 'Says "hi" back');
	assert.equal(fields.when_to_use, 'Always consult when committing — "commit", "コミット".');
	assert.equal(fields.notes, "line one\nline two");
	assert.equal(fields.wrapped, "first part second part");
	assert.equal(fields["allowed-tools"], "- Bash(git:*) - Read");
	assert.equal(fields["disable-model-invocation"], "true");
});

test("a file without frontmatter has no fields and keeps its body", () => {
	assert.deepEqual(frontmatter("# Title\n\nname: not a field\n"), {});
	assert.equal(stripFrontmatter("---\nname: a\n---\n# Body\n"), "# Body\n");
	assert.equal(stripFrontmatter("# Body\n"), "# Body\n");
});

function claudeHome(): { home: string; cache: string } {
	const home = tree({
		".claude/settings.json": JSON.stringify({
			enabledPlugins: { "team@work": true, "bridge@vendor": true, "off@work": false, "missing@work": true },
		}),
	});
	const cache = join(home, ".claude", "plugins", "cache");
	const installs = (name: string, scope = "user") => [{ scope, installPath: join(cache, name) }];
	for (const name of ["team", "bridge", "off", "repo-only"]) mkdirSync(join(cache, name), { recursive: true });
	writeFileSync(
		join(home, ".claude", "plugins", "installed_plugins.json"),
		JSON.stringify({
			version: 2,
			plugins: {
				"team@work": installs("team"),
				"bridge@vendor": installs("bridge"),
				"off@work": installs("off"),
				"repo-only@work": installs("repo-only", "project"),
				// Enabled but never installed: nothing on disk to load.
				"missing@work": [{ scope: "user", installPath: join(cache, "gone") }],
			},
		}),
	);
	return { home, cache };
}

test("enabled and installed plugins are found, user settings first", () => {
	const { home, cache } = claudeHome();
	assert.deepEqual(enabledPlugins({ home, cwd: join(home, "code", "repo") }), [
		{ name: "team", root: join(cache, "team") },
		{ name: "bridge", root: join(cache, "bridge") },
	]);
	assert.deepEqual(
		enabledPlugins({ home, cwd: join(home, "code", "repo"), exclude: ["bridge"] }).map((plugin) => plugin.name),
		["team"],
	);
});

test("project settings add and remove plugins for directories below them", () => {
	const { home } = claudeHome();
	const repo = join(home, "code", "repo");
	mkdirSync(join(repo, ".claude"), { recursive: true });
	writeFileSync(join(repo, ".claude", "settings.json"), JSON.stringify({ enabledPlugins: { "repo-only@work": true } }));
	writeFileSync(join(repo, ".claude", "settings.local.json"), JSON.stringify({ enabledPlugins: { "bridge@vendor": false } }));

	const names = (cwd: string) => enabledPlugins({ home, cwd }).map((plugin) => plugin.name);
	assert.deepEqual(names(join(repo, "packages", "app")), ["team", "repo-only"]);
	assert.deepEqual(names(join(home, "code", "other")), ["team", "bridge"]);
});

test("unreadable Claude Code state yields no plugins", () => {
	const home = tree({ ".claude/settings.json": "{ not json" });
	assert.deepEqual(enabledPlugins({ home, cwd: home }), []);
	assert.deepEqual(enabledPlugins({ home: join(home, "absent"), cwd: home }), []);
});

test("plugin skills are named <plugin>:<name> and skipped without a description", () => {
	const root = tree({
		"skills/creating-pr/SKILL.md": "---\nname: creating-pr\ndescription: Creates a PR: draft first.\nwhen_to_use: When opening a PR.\n---\nbody",
		"skills/by-dir/SKILL.md": "---\ndescription: Named after its directory.\ndisable-model-invocation: true\n---\nbody",
		"skills/no-description/SKILL.md": "---\nname: no-description\n---\nbody",
		"skills/not-a-skill/README.md": "notes",
	});
	const skills = pluginSkills({ name: "team", root });
	assert.deepEqual(
		skills.map((skill) => [skill.qualifiedName, skill.description, skill.manualOnly]),
		[
			["team:by-dir", "Named after its directory.", true],
			["team:creating-pr", "Creates a PR: draft first. When opening a PR.", false],
		],
	);
	assert.equal(skills[1].file, join(root, "skills", "creating-pr", "SKILL.md"));
	assert.deepEqual(pluginSkills({ name: "empty", root: join(root, "skills", "not-a-skill") }), []);
});

test("MCP server placeholders are expanded, and a server missing a value is skipped", () => {
	const root = tree({
		".mcp.json": JSON.stringify({
			mcpServers: {
				docs: { type: "http", url: "https://example.com/mcp" },
				local: { command: "${CLAUDE_PLUGIN_ROOT}/bin/server", args: ["--region", "${REGION:-us}"], env: { TOKEN: "${TEAM_TOKEN}" } },
				keyed: { type: "http", url: "https://example.com/mcp", headers: { Authorization: "Bearer ${ABSENT_KEY}" } },
			},
		}),
	});
	const { servers, skipped } = pluginMcpServers({ name: "team", root }, { TEAM_TOKEN: "t0ken" });
	assert.deepEqual(servers, [
		{ plugin: "team", name: "docs", config: { type: "http", url: "https://example.com/mcp" } },
		{ plugin: "team", name: "local", config: { command: `${root}/bin/server`, args: ["--region", "us"], env: { TOKEN: "t0ken" } } },
	]);
	assert.deepEqual(skipped, ["team:keyed (needs ABSENT_KEY)"]);
});

test("a server list written without the mcpServers wrapper is read too", () => {
	const root = tree({ ".mcp.json": JSON.stringify({ notion: { type: "http", url: "https://example.com/mcp" } }) });
	assert.deepEqual(
		pluginMcpServers({ name: "team", root }, {}).servers.map((server) => server.name),
		["notion"],
	);
	assert.deepEqual(pluginMcpServers({ name: "none", root: join(root, "absent") }, {}), { servers: [], skipped: [] });
});
