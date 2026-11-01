import assert from "node:assert/strict";
import { test } from "node:test";
import { type Rules, canonicalPath, decide, normalizeToolPath, splitCommand } from "./rules.ts";

const home = "/Users/me";
const opts = { home };

const rules: Rules = {
	deny: {
		bash: ["rm* -rf*", "dd", "dd *", "gh* repo delete*"],
		read: [".env", ".env.*", "~/.ssh/id_*", "**/secrets/*.age", "//run/agenix/**", "**/.*token*"],
		edit: [".env*", "**/.git/**"],
	},
	ask: {
		bash: ["git push* --force", "git push* --force *", "sudo *", "sudo"],
		edit: ["**/.config/pi/**"],
	},
};

const bash = (command: string) => decide(rules, "bash", [command], opts);
const read = (path: string) => decide(rules, "read", [path], opts);
const edit = (path: string) => decide(rules, "edit", [path], opts);

test("bash: deny patterns match the whole command with * as anything", () => {
	assert.equal(bash("rm -rf build")?.decision, "deny");
	assert.equal(bash("rm -rfv build")?.decision, "deny");
	assert.equal(bash("gh api repo delete-me")?.decision, "deny");
	assert.equal(bash("rm file.txt"), undefined);
});

test("bash: a bare word pattern does not match a longer word", () => {
	assert.equal(bash("dd if=/dev/zero")?.decision, "deny");
	assert.equal(bash("ddgr query"), undefined);
});

test("bash: ask patterns are consulted after deny", () => {
	assert.deepEqual(bash("git push origin main --force"), { decision: "ask", pattern: "git push* --force" });
	assert.equal(bash("git push --force origin main")?.decision, "ask");
	assert.equal(bash("git push --force-with-lease"), undefined);
	assert.equal(bash("sudo")?.decision, "ask");
});

test("bash: every segment of a compound command is checked", () => {
	assert.equal(bash("ls; rm -rf build")?.decision, "deny");
	assert.equal(bash("make && sudo make install")?.decision, "ask");
	assert.equal(bash("cat x | dd of=/dev/sda")?.decision, "deny");
	assert.equal(bash("ls\nrm -rf build")?.decision, "deny");
	assert.equal(bash("(rm -rf build)")?.decision, "deny");
	assert.equal(bash("ls && git status"), undefined);
});

test("splitCommand drops empty segments and leading group openers", () => {
	assert.deepEqual(splitCommand("a && b || c; { d; }"), ["a", "b", "c", "d", "}"]);
	assert.deepEqual(splitCommand("  "), []);
});

test("path: a bare pattern matches the tail of an absolute path", () => {
	assert.equal(read("/repo/.env")?.decision, "deny");
	assert.equal(read("/repo/.env.local")?.decision, "deny");
	assert.equal(read("/repo/env"), undefined);
	assert.equal(read("/repo/my.env"), undefined);
});

test("path: ~ expands to home and * stays within a segment", () => {
	assert.equal(read("/Users/me/.ssh/id_ed25519")?.decision, "deny");
	assert.equal(read("/Users/me/.ssh/config"), undefined);
	assert.equal(read("/Users/other/.ssh/id_rsa"), undefined);
});

test("path: ** crosses segments and // anchors at the root", () => {
	assert.equal(read("/repo/.config/nix/secrets/key.age")?.decision, "deny");
	assert.equal(read("/repo/secrets/key.age")?.decision, "deny");
	assert.equal(read("/repo/secrets/nested/key.age"), undefined);
	assert.equal(read("/run/agenix/github-token")?.decision, "deny");
	assert.equal(read("/repo/run/agenix/github-token"), undefined);
	assert.equal(read("/repo/.npm-token-file")?.decision, "deny");
});

test("path: rules are per tool, ask after deny", () => {
	assert.equal(edit("/repo/.git/config")?.decision, "deny");
	assert.equal(edit("/repo/.env.production")?.decision, "deny");
	assert.equal(edit("/Users/me/dotfiles/.config/pi/settings.json")?.decision, "ask");
	assert.equal(decide(rules, "write", ["/repo/.env"], opts), undefined);
	assert.equal(read("/repo/.git/config"), undefined);
});

test("path: case is ignored when asked to", () => {
	assert.equal(read("/repo/.ENV"), undefined);
	assert.equal(decide(rules, "read", ["/repo/.ENV"], { home, ignoreCase: true })?.decision, "deny");
});

test("path: any of the given subjects may match", () => {
	assert.equal(decide(rules, "read", ["/repo/link", "/repo/.env"], opts)?.decision, "deny");
});

test("missing sections are treated as empty", () => {
	assert.equal(decide({}, "bash", ["rm -rf /"], opts), undefined);
	assert.equal(decide({ deny: {} }, "read", ["/repo/.env"], opts), undefined);
});

test("normalizeToolPath mirrors the tools: @ prefix, ~, relative to cwd", () => {
	assert.equal(normalizeToolPath("@.env", "/repo", home), "/repo/.env");
	assert.equal(normalizeToolPath("~/.ssh/id_rsa", "/repo", home), "/Users/me/.ssh/id_rsa");
	assert.equal(normalizeToolPath("~", "/repo", home), "/Users/me");
	assert.equal(normalizeToolPath("src/../.env", "/repo", home), "/repo/.env");
	assert.equal(normalizeToolPath("/abs/x", "/repo", home), "/abs/x");
});

test("canonicalPath resolves the deepest existing ancestor", () => {
	const links: Record<string, string> = { "/repo/link": "/secret", "/repo": "/repo", "/": "/" };
	const realpath = (p: string) => {
		if (p in links) return links[p];
		throw new Error("ENOENT");
	};
	assert.equal(canonicalPath("/repo/link", realpath), "/secret");
	assert.equal(canonicalPath("/repo/link/new/file.txt", realpath), "/secret/new/file.txt");
	assert.equal(canonicalPath("/repo/plain.txt", realpath), "/repo/plain.txt");
	assert.equal(canonicalPath("/nowhere/x", () => { throw new Error("ENOENT"); }), "/nowhere/x");
});
