# CLAUDE.md

Personal dotfiles for macOS (Apple Silicon) using Nix Flakes + nix-darwin + Home Manager. System settings, user packages, and Homebrew are all declarative; two host outputs are defined: `personal` and `work`.

## Apply / verify

Entry point: `.config/nix/flake.nix` (defines `darwinConfigurations.{personal,work}`).

```bash
sudo darwin-rebuild switch --flake .config/nix#personal   # apply (use #work on the work host)
sudo darwin-rebuild build  --flake .config/nix#personal   # build only, no activation
sudo darwin-rebuild check  --flake .config/nix#personal   # build + activation checks, no switch
nix flake check .config/nix                               # syntax / eval check
```

The active host also exposes shell aliases `dr` / `drb` / `drc` for the three `darwin-rebuild` commands.

## Layout

- `.config/nix/flake.nix` — entry point; `mkHost` composes the shared module trees per host, inputs flow to modules via `specialArgs.inputs`
- `.config/nix/modules/host-spec.nix` — defines `config.hostSpec.{hostName,username,isWork}` and derives hostname / primary user / user account from it
- `.config/nix/darwin/` — system-level: macOS prefs, nix settings, Homebrew, agenix, Home Manager wiring (each file imports the upstream module it configures)
- `.config/nix/home-manager/` — user-level: Nix packages, dotfile symlinks, per-program config under `programs/`
- `.config/nix/hosts/{personal,work}/` — per-host `hostSpec` values + host-only Homebrew lists; `hosts/common/` holds the shared system + Homebrew package lists
- `.config/nix/secrets/` — agenix-encrypted SSH/GPG keys and API tokens

Homebrew is fully declarative via nix-homebrew — never run `brew bundle` or `brew install` manually.

## Agent permission mirror

The Claude Code permission tiers in `.config/claude/settings.json` (`permissions.allow` / `ask` / `deny`) are mirrored into each other agent's native format. Whenever a permission entry changes there, update the mirrors in the same change:

- Codex — `.config/codex/rules/managed.rules` (execpolicy `prefix_rule`; allow / prompt / forbidden ≙ allow / ask / deny). Verify with `codex execpolicy check --rules <file> -- <command>`
- Devin CLI — `.config/devin/permissions.json` (same `allow` / `ask` / `deny` keys; `Bash(...)` ≙ `Exec(<prefix>)`, `Edit`/`Write` ≙ `Write(<glob>)`, `Bash` ≙ tool name `exec`). The `devinPermissionsSync` activation in `home-manager/dotfiles.nix` replaces the `permissions` block of `~/.config/devin/config.json` on every `darwin-rebuild switch` (work host only) and warns about entries it drops. Devin imports Claude's rules / skills / MCP servers but never its permissions, hence this mirror
- Cursor CLI — `.config/cursor/permissions.json` (`allow` / `deny` only, in Cursor token syntax: `Bash(cmd* args*)` ≙ `Shell(cmd:*args*)`, `Read`/`Edit` ≙ `Read(<glob>)`/`Write(<glob>)`, `mcp__<server>__<tool>` ≙ `Mcp(<server>:<tool>)`, `Bash` ≙ `Shell(*)`). The `cursorPermissionsSync` activation in `home-manager/dotfiles.nix` (work host only) replaces the `permissions` block of `~/.cursor/cli-config.json` (expanding `~/` in `Read()`/`Write()`), sets `autoAcceptWebSearch`, and warns about entries it drops

Known fidelity gaps, accepted deliberately:

- Codex rules only govern commands escalated out of the sandbox and cannot express `Read()`/`Edit()` denies.
- Devin `Exec()` is an argv prefix, so Claude globs with a wildcard in the middle (`rm* -rf*`, `aws* iam delete-*`, `git push* --force*`) are enumerated the same way as in Codex; a flag placed after the target (`git push origin main --force`, `rm -rfv`) is not caught. `Read()`/`Write()` globs without a leading `/` or `~` are cwd-relative in Devin, so the mirror prefixes them with `/**/`. MCP entries use Devin's server names (`mcp__context7__*`, not `mcp__plugin_mcp_context7__*`) and list only servers configured for Devin; `Skill(...)` has no equivalent.
- Cursor has no `ask` tier, so Claude's `ask` entries are deliberately folded into `allow` (`Shell(*)` already covers them) rather than promoted to `deny`. `Shell(cmd:args)` globs the argument string after the first token, so Claude's `cmd* x*` becomes `cmd:*x*` (one entry, slightly broader); how compound commands are matched is undocumented. The mirror covers the CLI only: the IDE reads `~/.cursor/permissions.json` (allowlist, no deny). Plugin MCP servers are named `plugin-<plugin>-<server>` (`plugin-mcp-serena`, not `plugin_mcp_serena`); `Skill(...)` has no equivalent.

## Where to look for task-specific context

Decide if any of these are relevant to the current task and read them first; otherwise skip:

- `agent_docs/architecture.md` — module composition, configuration flow, how `hostSpec` propagates
- `agent_docs/extending.md` — adding hosts, Nix packages, Homebrew packages, dotfile symlinks, or Home Manager program modules (points at existing examples in the tree)
- `agent_docs/secrets.md` — agenix workflow: new-machine setup, adding a new secret, re-encrypting

For new program modules under `home-manager/programs/`, the closest existing module is the best reference — match its structure rather than improvising.
