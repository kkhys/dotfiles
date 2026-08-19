# Extending the configuration

Patterns for the most common additions. In every case, the closest existing example in the tree is the authoritative reference — match its structure rather than the snippets here.

## Add a Nix package (user-level)

Edit `.config/nix/home-manager/packages.nix` and add to `home.packages`. Work-only packages go behind `lib.mkIf config.hostSpec.isWork`.

## Add a Homebrew package or cask

Three files, choose by scope:

- All hosts → `.config/nix/hosts/common/homebrew.nix`
- Personal only → `.config/nix/hosts/personal/homebrew.nix`
- Work only → `.config/nix/hosts/work/homebrew.nix`

Host scoping comes from which host imports the file — no `lib.mkIf` needed. Use `homebrew.brews` for formulae and `homebrew.casks` for GUI apps.

## Add a Home Manager program module

1. Create `.config/nix/home-manager/programs/<tool>.nix` modeled on the closest existing one (e.g. `git.nix`, `zsh.nix`, `fzf.nix`)
2. Import it from `.config/nix/home-manager/default.nix`

If the tool needs raw config files rather than a `programs.<tool>` HM module, manage them as symlinks instead (see below).

## Add a dotfile symlink

Edit `.config/nix/home-manager/dotfiles.nix`:

- For `~/.config/<...>` files, append to the `configFiles` list
- For files at `$HOME`, add an entry to `home.file` using the `mkLink` helper defined in the same file

`mkLink` produces an out-of-store symlink back into this repo, so edits in the working tree are picked up without rebuilding.

## Add an agent skill or MCP server

- A third-party skill from the skills registry: append to `agentSkills` in `.config/nix/home-manager/skills.nix`. The CLI installs it into `~/.agents/skills`, which Codex, Gemini CLI, Cursor, Devin and Copilot CLI read; Claude Code gets it through `~/.claude/skills`
- Your own skill: add it to the `base` plugin of `kkhys/claude-code-marketplace`. `skills.nix` links every `plugins/*/skills/<name>/` of the local checkout into `~/.agents/skills/<name>` on rebuild; Claude Code loads the same skill from the installed plugin, so no entry is needed here
- An MCP server: add it to `plugins/mcp/.mcp.json` in the marketplace and bump that plugin's version. `mcp.nix` installs the plugin into Codex and Copilot, links it into Devin, and renders the Gemini extension and Cursor `mcp.json` from the file; Claude Code picks it up through `enabledPlugins` in `.config/claude/settings*.json`, where the `mcp__plugin_mcp_<server>__*` permission entries also live

## Add a new host

1. Create `.config/nix/hosts/<host>/default.nix` modeled on `hosts/personal/default.nix`. It only sets `hostSpec.{hostName,username,isWork}` and imports a sibling `homebrew.nix` for host-only packages — hostname, primary user, and the `dr` / `drb` / `drc` aliases all derive from `hostSpec` automatically
2. Add `<host> = mkHost "<host>";` to `darwinConfigurations` in `.config/nix/flake.nix`
3. Apply with `sudo darwin-rebuild switch --flake .config/nix#<host>`

## Verify

Before committing:

```bash
sudo darwin-rebuild build --flake .config/nix#personal   # build only, no activation
nix flake check .config/nix
(cd .config/nix && nix fmt)                              # nixfmt-tree, from the flake's formatter output
```

Build on the host you actually use; for cross-host changes, build both `personal` and `work` if possible.
