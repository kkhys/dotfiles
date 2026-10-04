// Run with: node --test .config/pi/extensions/permission-gate/

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { commandForms, decide, parseRules, type Tier } from "./rules.ts";

const env = { cwd: "/work/repo", home: "/Users/me" };

const rules = parseRules({
	allow: ["Bash", "Read", "Edit", "Write", "mcp__plugin_mcp_serena__*", "mcp__qase__*", "mcp__plugin_mcp_chrome-devtools__*"],
	ask: [
		"Bash(git push* --force *)",
		"Bash(git push* --force)",
		"Bash(git push* -f)",
		"Bash(sudo:*)",
		"Bash(gh* pr merge*)",
		"mcp__plugin_miitel-softphone_qase__qase_*_delete",
	],
	deny: [
		"mcp__plugin_mcp_serena__execute_shell_command",
		"Bash(rm* -rf*)",
		"Bash(rm* -fr*)",
		"Bash(dd:*)",
		"Bash(aws* s3 rm*)",
		"Bash(terraform* apply*)",
		"Read(.env)",
		"Read(.env.*)",
		"Read(~/.aws/**)",
		"Read(~/.ssh/id_*)",
		"Read(**/secrets/*.age)",
		"Read(/run/agenix/**)",
		"Read(**/.*token*)",
		"Edit(.env*)",
		"Edit(~/.ssh/**)",
	],
});

const bash = (command: string) => decide(rules, "bash", { command }, env).tier;
const file = (tool: string, path?: string) => decide(rules, tool, path === undefined ? {} : { path }, env).tier;

const expectBash = (tier: Tier, commands: string[]) => {
	for (const command of commands) assert.equal(bash(command), tier, command);
};

test("deny rules match the command wherever it sits in the line", () => {
	expectBash("deny", [
		"rm -rf build",
		"rm build -rf",
		"cd /tmp && rm -rf build",
		"ls | xargs echo; rm -fr build",
		"FOO=1 rm -rf build",
		"env FOO=1 rm -rf build",
		"timeout 10 rm -rf build",
		"echo $(aws s3 rm s3://bucket/key)",
		'echo "$(terraform apply -auto-approve)"',
		"echo `dd if=/dev/zero of=x`",
		'bash -lc "terraform -chdir=infra apply"',
		"eval 'rm -rf build'",
		"(cd infra && terraform apply)",
		"dd",
	]);
});

test("a deny rule outranks an ask rule on the same line", () => {
	assert.equal(bash("sudo rm -rf /var/x"), "deny");
});

test("text that only mentions a denied command is not blocked", () => {
	expectBash("allow", [
		'git commit -m "docs: never run rm -rf"',
		"rg 'terraform apply' docs",
		"rmdir build",
		"ddgr query",
		"terraform plan",
		"ls -la; echo done",
	]);
});

test("ask rules cover both the bare and the argument form", () => {
	expectBash("ask", [
		"git push --force",
		"git push origin main --force",
		"git push --force origin main",
		"git push origin main -f",
		"sudo ls",
		"sudo",
		"gh pr merge 12 --squash",
		"git fetch && git push --force",
	]);
	expectBash("allow", ["git push", "git push --force-with-lease", "sudoedit /etc/hosts"]);
});

test("read rules follow gitignore anchoring", () => {
	for (const path of [
		".env",
		"apps/web/.env",
		"/work/repo/.env.local",
		"~/.aws/credentials",
		"/Users/me/.aws/sso/cache/x.json",
		"../../Users/me/.ssh/id_ed25519",
		".config/nix/secrets/github-token.age",
		"/run/agenix/npm-token",
		"apps/.npm_token_cache",
	]) {
		assert.equal(file("read", path), "deny", path);
		assert.equal(file("grep", path), "deny", path);
	}
	for (const path of ["src/env.ts", ".envrc", "~/.ssh/config", "/Users/other/.aws/credentials", "docs/secrets/readme.md"]) {
		assert.equal(file("read", path), "allow", path);
	}
	assert.equal(file("ls"), "allow");
});

test("edit rules apply to edit and write, and only to those", () => {
	for (const tool of ["edit", "write"]) {
		assert.equal(file(tool, ".envrc"), "deny");
		assert.equal(file(tool, "~/.ssh/config"), "deny");
		assert.equal(file(tool, "src/index.ts"), "allow");
	}
	assert.equal(file("read", "~/.ssh/config"), "allow");
});

test("MCP rules written for Claude Code plugin servers match Pi tool names", () => {
	const mcp = (name: string) => decide(rules, name, {}, env).tier;
	assert.equal(mcp("mcp__serena__execute_shell_command"), "deny");
	assert.equal(mcp("mcp__serena__find_symbol"), "allow");
	assert.equal(mcp("mcp__chrome_devtools__take_screenshot"), "allow");
	assert.equal(mcp("mcp__qase__qase_case_get"), "allow");
	assert.equal(mcp("mcp__qase__qase_case_delete"), "ask");
	assert.equal(mcp("mcp__unlisted__anything"), "ask");
});

test("a server-wide MCP rule covers every tool of that server", () => {
	const serverWide = parseRules({ allow: ["mcp__context7"] });
	assert.equal(decide(serverWide, "mcp__context7__query-docs", {}, env).tier, "allow");
	assert.equal(decide(serverWide, "mcp__context7_other__x", {}, env).tier, "ask");
});

test("without a blanket allow, an uncovered call needs confirmation", () => {
	const narrow = parseRules({ allow: ["Bash(git status:*)", "Read"] });
	assert.equal(decide(narrow, "bash", { command: "git status -s" }, env).tier, "allow");
	assert.equal(decide(narrow, "bash", { command: "git status && curl example.com" }, env).tier, "ask");
	assert.equal(decide(narrow, "write", { path: "a.txt" }, env).tier, "ask");
});

test("extension tools have no Claude Code rule and pass", () => {
	assert.equal(decide(rules, "Agent", { prompt: "rm -rf /" }, env).tier, "allow");
});

test("quoted separators do not split a command", () => {
	assert.deepEqual(commandForms('git commit -m "a; b && c"'), [['git commit -m "a; b && c"', "git commit -m a; b && c"]]);
});

// Guards the premise of this extension: every restriction in the real
// permission lists is one the gate can enforce. A deny or ask entry for a tool
// it has no matcher for would be silently ignored in Pi.
test("every deny and ask entry in the Claude settings is enforceable", () => {
	const claudeDir = join(dirname(fileURLToPath(import.meta.url)), "../../../claude");
	for (const name of ["settings.json", "settings-work.json"]) {
		const parsed = parseRules(JSON.parse(readFileSync(join(claudeDir, name), "utf8")).permissions);
		const restrictions = parsed.filter((rule) => rule.tier !== "allow");
		assert.ok(restrictions.length > 0, `${name} has restrictions`);
		for (const rule of restrictions) {
			assert.match(rule.tool, /^(?:Bash|Read|Edit|Write|mcp__.+)$/, `${name}: ${rule.source}`);
		}
	}
});
