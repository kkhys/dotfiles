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

The Claude Code permission tiers in `.config/claude/settings.json` (`permissions.allow` / `ask` / `deny`) are mirrored into Codex's `.config/codex/rules/managed.rules` (execpolicy `prefix_rule`; allow / prompt / forbidden ≙ allow / ask / deny, except for the irreversible part of `ask` noted below). Whenever a permission entry changes there, update the mirror in the same change.

Verify with `codex execpolicy check --rules <file> -- <command>`; a rule's `match` / `not_match` examples are checked whenever the file is loaded, so a wrong prefix fails the command rather than passing silently. The `codexRulesSync` activation in `home-manager/dotfiles.nix` copies it to `~/.codex/rules/managed.rules` as a regular file on every `darwin-rebuild switch` — Codex skips symlinked `*.rules`, so it must not be a `home.file` link — and Codex loads rules only at startup, so restart it after a switch.

Known fidelity gaps, accepted deliberately:

- Codex rules only govern commands escalated out of the sandbox and cannot express `Read()`/`Edit()` denies.
- Codex answers a `prompt` decision with the reviewer subagent, not a person (`approvals_reviewer = "auto_review"` in `.config/codex/config.toml`), so Claude `ask` entries that a wrong answer cannot undo — `git push --force`, `git reset --hard`, `git clean`, `gh pr merge`, `sudo`, `npm`/`pnpm publish` — are `forbidden` there rather than `prompt`. Changing `approvals_reviewer` back to `user` is what would justify demoting them to `prompt` again.
- Codex splits a shell script into its component commands only when it is a linear chain of plain words joined by `&&`, `||`, `;` or `|`; a redirect, substitution, variable or glob anywhere in it makes the whole script one `zsh -lc <script>` argv that no `prefix_rule` matches. Such invocations always reach the reviewer, whatever the tiers say. Note that `codex execpolicy check` does not perform that split at all, so test rules with the bare argv (`-- gh pr view 1`), never through a shell wrapper.
## Where to look for task-specific context

Decide if any of these are relevant to the current task and read them first; otherwise skip:

- `agent_docs/architecture.md` — module composition, configuration flow, how `hostSpec` propagates
- `agent_docs/extending.md` — adding hosts, Nix packages, Homebrew packages, dotfile symlinks, or Home Manager program modules (points at existing examples in the tree)
- `agent_docs/secrets.md` — agenix workflow: new-machine setup, adding a new secret, re-encrypting

For new program modules under `home-manager/programs/`, the closest existing module is the best reference — match its structure rather than improvising.
