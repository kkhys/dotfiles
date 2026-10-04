# Extending the configuration

Patterns for the most common additions. In every case, the closest existing example in the tree is the authoritative reference — match its structure rather than the snippets here.

## Add a Nix package (user-level)

Edit `.config/nix/home-manager/packages.nix` and add to `home.packages`. Work-only packages go in the `lib.optionals hostSpec.isWork` list at the end of the file.

## Add a Homebrew package or cask

Three files, choose by scope:

- All hosts → `.config/nix/hosts/common/homebrew.nix`
- Personal only → `.config/nix/hosts/personal/homebrew.nix`
- Work only → `.config/nix/hosts/work/homebrew.nix`

Host scoping comes from which host imports the file — no `lib.mkIf` needed. Use `homebrew.brews` for formulae and `homebrew.casks` for GUI apps.

## Add a Homebrew tap

A package from a third-party tap needs the tap registered first, in three places (see `stablyai/orca` for a worked example):

1. `.config/nix/flake.nix` — a `flake = false` input pointing at the `homebrew-<name>` repository
2. `.config/nix/darwin/homebrew.nix` — the tap name in `homebrew.taps`, and the repository-to-input mapping in `nix-homebrew.taps`
3. The host's `homebrew.nix` — the package itself, written fully qualified as `<owner>/<tap>/<package>`

Taps are pinned to the flake input, so `nix flake update` is what moves them; `brew update` cannot write to the read-only store copy.

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

- A third-party skill from the skills registry: append to `agentSkills` in `.config/nix/home-manager/skills.nix`. The CLI installs it into `~/.agents/skills`, which Codex and Pi read; Claude Code gets it through `~/.claude/skills`
- Your own skill: add it to the `base` plugin of `kkhys/claude-code-marketplace`. `skills.nix` links every `plugins/*/skills/<name>/` of the local checkout into `~/.agents/skills/<name>` on rebuild; Claude Code loads the same skill from the installed plugin, so no entry is needed here
- An MCP server: add it to `plugins/mcp/.mcp.json` in the marketplace and bump that plugin's version. `mcp.nix` installs the plugin into Codex and copies its `.mcp.json` to `~/.pi/agent/mcp.json` for Pi; Claude Code picks it up through `enabledPlugins` in `.config/claude/settings*.json`, where the `mcp__plugin_mcp_<server>__*` permission entries also live
- A Claude Code plugin from another marketplace needs nothing here for Pi: the `claude-compat` extension reads Claude Code's `enabledPlugins` and install registry at session start and loads the skills (as `<plugin>:<name>`) and MCP servers of whatever is enabled there, for the user and for the project Pi runs in. To keep one out of Pi, add its name to `claudePlugins.exclude` in `.config/pi/settings.jsonc`
- A Pi extension: add a `.ts` file, or a directory with an `index.ts`, under `.config/pi/extensions/`. The directory is linked as a whole, so `/reload` in Pi picks it up without a rebuild; any other file in a subdirectory (helpers, tests) is not loaded as an extension
- A third-party Pi package: add it to `packages` in `.config/pi/settings.jsonc`, pinned to an exact version or commit, since extensions run inside the Pi process with full user permissions. The `piSettingsSync` activation merges that file over `~/.pi/agent/settings.json` on the next rebuild

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
