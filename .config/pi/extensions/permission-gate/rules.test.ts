import assert from "node:assert/strict";
import { test } from "node:test";
import { type Rules, decide } from "./rules.ts";

const home = "/Users/me";

const rules: Rules = {
	deny: {
		bash: ["rm* -rf*", "dd", "dd *", "gh* repo delete*"],
		read: [".env", ".env.*", "~/.ssh/id_*", "**/secrets/*.age", "//run/agenix/**", "**/.*token*"],
		edit: [".env*", "**/.git/**"],
	},
	ask: {
		bash: ["git push* --force", "git push* --force *", "sudo *", "sudo"],
	},
};

test("bash: deny patterns match the whole command with * as anything", () => {
	assert.equal(decide(rules, "bash", "rm -rf build", home)?.decision, "deny");
	assert.equal(decide(rules, "bash", "rm -rfv build", home)?.decision, "deny");
	assert.equal(decide(rules, "bash", "gh api repo delete-me", home)?.decision, "deny");
	assert.equal(decide(rules, "bash", "rm file.txt", home), undefined);
});

test("bash: a bare word pattern does not match a longer word", () => {
	assert.equal(decide(rules, "bash", "dd if=/dev/zero", home)?.decision, "deny");
	assert.equal(decide(rules, "bash", "ddgr query", home), undefined);
});

test("bash: ask patterns are consulted after deny", () => {
	assert.deepEqual(decide(rules, "bash", "git push origin main --force", home), {
		decision: "ask",
		pattern: "git push* --force",
	});
	assert.equal(decide(rules, "bash", "git push --force origin main", home)?.decision, "ask");
	assert.equal(decide(rules, "bash", "git push --force-with-lease", home), undefined);
	assert.equal(decide(rules, "bash", "sudo", home)?.decision, "ask");
});

test("path: a bare pattern matches the tail of an absolute path", () => {
	assert.equal(decide(rules, "read", "/repo/.env", home)?.decision, "deny");
	assert.equal(decide(rules, "read", "/repo/.env.local", home)?.decision, "deny");
	assert.equal(decide(rules, "read", "/repo/env", home), undefined);
	assert.equal(decide(rules, "read", "/repo/my.env", home), undefined);
});

test("path: ~ expands to home and * stays within a segment", () => {
	assert.equal(decide(rules, "read", "/Users/me/.ssh/id_ed25519", home)?.decision, "deny");
	assert.equal(decide(rules, "read", "/Users/me/.ssh/config", home), undefined);
	assert.equal(decide(rules, "read", "/Users/other/.ssh/id_rsa", home), undefined);
});

test("path: ** crosses segments and // anchors at the root", () => {
	assert.equal(decide(rules, "read", "/repo/.config/nix/secrets/key.age", home)?.decision, "deny");
	assert.equal(decide(rules, "read", "/repo/secrets/key.age", home)?.decision, "deny");
	assert.equal(decide(rules, "read", "/repo/secrets/nested/key.age", home), undefined);
	assert.equal(decide(rules, "read", "/run/agenix/github-token", home)?.decision, "deny");
	assert.equal(decide(rules, "read", "/repo/run/agenix/github-token", home), undefined);
	assert.equal(decide(rules, "read", "/repo/.npm-token-file", home)?.decision, "deny");
});

test("path: rules are per tool", () => {
	assert.equal(decide(rules, "edit", "/repo/.git/config", home)?.decision, "deny");
	assert.equal(decide(rules, "edit", "/repo/.env.production", home)?.decision, "deny");
	assert.equal(decide(rules, "write", "/repo/.env", home), undefined);
	assert.equal(decide(rules, "read", "/repo/.git/config", home), undefined);
});

test("missing sections are treated as empty", () => {
	assert.equal(decide({}, "bash", "rm -rf /", home), undefined);
	assert.equal(decide({ deny: {} }, "read", "/repo/.env", home), undefined);
});
