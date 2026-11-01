import assert from "node:assert/strict";
import { test } from "node:test";
import {
	type FsLike,
	type Rules,
	decide,
	literalDirectory,
	normalizeToolPath,
	pathForms,
	splitCommand,
	withCanonicalPrefixes,
} from "./rules.ts";

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

test("bash: ask patterns are consulted after deny and report the subject", () => {
	assert.deepEqual(bash("git push origin main --force"), {
		decision: "ask",
		pattern: "git push* --force",
		subject: "git push origin main --force",
	});
	assert.equal(bash("git push --force origin main")?.decision, "ask");
	assert.equal(bash("git push --force-with-lease"), undefined);
	assert.equal(bash("sudo")?.decision, "ask");
});

test("bash: every segment of a compound command is checked, and the whole line too", () => {
	assert.equal(bash("ls; rm -rf build")?.decision, "deny");
	assert.equal(bash("make && sudo make install")?.decision, "ask");
	assert.equal(bash("cat x | dd of=/dev/sda")?.decision, "deny");
	assert.equal(bash("ls\nrm -rf build")?.decision, "deny");
	assert.equal(bash("(rm -rf build)")?.decision, "deny");
	assert.equal(bash("git push origin main --force 2>&1")?.decision, "ask");
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

test("path: any of the given subjects may match, and the one that did is reported", () => {
	assert.deepEqual(decide(rules, "read", ["/repo/link", "/repo/.env"], opts), {
		decision: "deny",
		pattern: ".env",
		subject: "/repo/.env",
	});
});

test("directory: a rule rooted under the directory applies to it", () => {
	const dir = { home, directory: true };
	assert.equal(decide(rules, "read", ["/Users/me/.ssh"], dir)?.decision, "deny");
	assert.equal(decide(rules, "read", ["/Users/me"], dir)?.decision, "deny");
	assert.equal(decide(rules, "read", ["/run"], dir)?.decision, "deny");
	assert.equal(decide(rules, "read", ["/"], dir)?.decision, "deny");
	assert.equal(decide(rules, "read", ["/users/ME/.SSH"], { ...dir, ignoreCase: true })?.decision, "deny");
	assert.equal(decide(rules, "read", ["/Users/me/projects"], dir), undefined);
	assert.equal(decide(rules, "read", ["/Users/me/.sshd"], dir), undefined);
	assert.equal(decide(rules, "read", ["/Users/me/.ssh"], opts), undefined);
});

test("literalDirectory takes the directory before the first wildcard", () => {
	assert.equal(literalDirectory("~/.ssh/id_*", home), "/Users/me/.ssh");
	assert.equal(literalDirectory("//run/agenix/**", home), "/run/agenix");
	assert.equal(literalDirectory("~/.aws/**", home), "/Users/me/.aws");
	assert.equal(literalDirectory("/etc/hosts", home), "/etc");
	assert.equal(literalDirectory(".env", home), undefined);
	assert.equal(literalDirectory("**/secrets/*.age", home), undefined);
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

function fakeFs(real: Record<string, string>, links: Record<string, string>): FsLike {
	return {
		realpath: (p) => {
			if (p in real) return real[p];
			throw new Error("ENOENT");
		},
		readlink: (p) => {
			if (p in links) return links[p];
			throw new Error("EINVAL");
		},
	};
}

test("pathForms: existing paths yield the path and its realpath", () => {
	const fs = fakeFs({ "/repo/link": "/secret", "/repo": "/repo", "/": "/", "/repo/plain.txt": "/repo/plain.txt" }, {});
	assert.deepEqual(pathForms("/repo/link", fs), ["/repo/link", "/secret"]);
	assert.deepEqual(pathForms("/repo/plain.txt", fs), ["/repo/plain.txt"]);
});

test("pathForms: a missing file is re-appended to its deepest existing ancestor", () => {
	const fs = fakeFs({ "/repo/link": "/secret", "/repo": "/repo", "/": "/" }, {});
	assert.deepEqual(pathForms("/repo/link/new/file.txt", fs), ["/repo/link/new/file.txt", "/secret/new/file.txt"]);
	assert.deepEqual(pathForms("/nowhere/x", fakeFs({ "/": "/" }, {})), ["/nowhere/x"]);
});

test("pathForms: a dangling symlink yields its target so a write through it is seen", () => {
	const fs = fakeFs({ "/repo": "/repo", "/Users/me/.ssh": "/Users/me/.ssh", "/": "/" }, { "/repo/key": "../Users/me/.ssh/newkey" });
	assert.deepEqual(pathForms("/repo/key", fs), ["/repo/key", "/Users/me/.ssh/newkey"]);
	assert.equal(decide(rules, "read", pathForms("/repo/key", fs), opts), undefined);
	const sshRules: Rules = { deny: { write: ["~/.ssh/**"] } };
	assert.equal(decide(sshRules, "write", pathForms("/repo/key", fs), opts)?.decision, "deny");
});

test("pathForms: a relative dangling link under a symlinked parent resolves against the real parent", () => {
	const fs = fakeFs({ "/repo": "/elsewhere/repo", "/elsewhere/repo": "/elsewhere/repo", "/elsewhere": "/elsewhere", "/": "/" }, {
		"/repo/key": "../.ssh/newkey",
	});
	assert.deepEqual(pathForms("/repo/key", fs), ["/repo/key", "/elsewhere/.ssh/newkey"]);
});

test("pathForms: a symlink loop stops at the hop limit", () => {
	const fs = fakeFs({ "/": "/" }, { "/a": "/b", "/b": "/a" });
	assert.ok(pathForms("/a", fs).length <= 3);
});

test("withCanonicalPrefixes adds a twin rule for a prefix behind a symlink", () => {
	const realpath = (p: string) => {
		if (p === "/run/agenix") return "/private/var/run/agenix";
		if (p === "/Users/me/.ssh") return "/Users/me/.ssh";
		throw new Error("ENOENT");
	};
	const out = withCanonicalPrefixes({ deny: { read: ["//run/agenix/**", "~/.ssh/id_*", ".env"], bash: ["dd"] } }, home, realpath);
	assert.deepEqual(out.deny?.read, ["//run/agenix/**", "//private/var/run/agenix/**", "~/.ssh/id_*", ".env"]);
	assert.deepEqual(out.deny?.bash, ["dd"]);
	assert.equal(decide(out, "read", ["/private/var/run/agenix/github-token"], opts)?.decision, "deny");
});
