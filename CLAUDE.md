# CLAUDE.md

Personal dotfiles for macOS (Apple Silicon) using Nix Flakes + nix-darwin + Home Manager. System settings, user packages, and Homebrew are all declarative; two host outputs are defined: `personal` and `work`.

## Apply / verify

Entry point: `.config/nix/flake.nix` (defines `darwinConfigurations.{personal,work}`).

```bash
sudo darwin-rebuild switch --flake .config/nix#personal   # apply (use #work on the work host)
sudo darwin-rebuild build  --flake .config/nix#personal   # build only, no activation
nix flake check .config/nix                               # syntax / eval check
```

The active host also exposes shell aliases `dr` / `drb` / `drc` for the same three commands.

## Layout

- `.config/nix/flake.nix` — entry point; `mkHost` composes the shared module trees per host, inputs flow to modules via `specialArgs.inputs`
- `.config/nix/modules/host-spec.nix` — defines `config.hostSpec.{hostName,username,isWork}` and derives hostname / primary user / user account from it
- `.config/nix/darwin/` — system-level: macOS prefs, nix settings, Homebrew, agenix, Home Manager wiring (each file imports the upstream module it configures)
- `.config/nix/home-manager/` — user-level: Nix packages, dotfile symlinks, per-program config under `programs/`
- `.config/nix/hosts/{personal,work}/` — per-host `hostSpec` values + host-only Homebrew lists; `hosts/common/` holds the shared system + Homebrew package lists
- `.config/nix/secrets/` — agenix-encrypted SSH/GPG keys and API tokens

Homebrew is fully declarative via nix-homebrew — never run `brew bundle` or `brew install` manually.

## Agent permission mirrors

The Claude Code permission tiers in `.config/claude/settings.json` (`permissions.allow` / `ask` / `deny`) are mirrored into each coding agent's native format. Whenever a permission entry changes there, update both mirrors in the same change:

- Codex — `.config/codex/rules/managed.rules` (execpolicy `prefix_rule`; allow / prompt / forbidden ≙ allow / ask / deny). Verify with `codex execpolicy check --rules <file> -- <command>`
- Copilot — the `copilot()` function in `.config/nix/home-manager/programs/zsh.nix` (`--allow-tool` / `--deny-tool` flags; Copilot has no ask tier, so ask-tier commands are simply left out of the allow list and prompt)

Known fidelity gaps, accepted deliberately: Codex rules only govern commands escalated out of the sandbox and cannot express `Read()`/`Edit()` denies; Copilot cannot express read denies and its allow list is an enumeration, so unlisted safe commands still prompt.

## Where to look for task-specific context

Decide if any of these are relevant to the current task and read them first; otherwise skip:

- `agent_docs/architecture.md` — module composition, configuration flow, how `hostSpec` propagates
- `agent_docs/extending.md` — adding hosts, Nix packages, Homebrew packages, dotfile symlinks, or Home Manager program modules (points at existing examples in the tree)
- `agent_docs/secrets.md` — agenix workflow: new-machine setup, adding a new secret, re-encrypting

For new program modules under `home-manager/programs/`, the closest existing module is the best reference — match its structure rather than improvising.
