# Extending the configuration

Patterns for the most common additions. In every case, the closest existing example in the tree is the authoritative reference — match its structure rather than the snippets here.

## Add a Nix package (user-level)

Edit `.config/nix/home-manager/packages.nix` and add to `home.packages`. Work-only packages go behind `lib.mkIf config.hostSpec.isWork`.

## Add a Homebrew package or cask

Three files, choose by scope:

- All hosts → `.config/nix/hosts/common/homebrew.nix`
- Personal only → `.config/nix/hosts/common/homebrew-personal.nix` (already wrapped in `lib.mkIf (!config.hostSpec.isWork)`)
- Work only → `.config/nix/hosts/common/homebrew-work.nix` (already wrapped in `lib.mkIf config.hostSpec.isWork`)

Use `homebrew.brews` for formulae and `homebrew.casks` for GUI apps.

## Add a Home Manager program module

1. Create `.config/nix/home-manager/programs/<tool>.nix` modeled on the closest existing one (e.g. `git.nix`, `zsh.nix`, `fzf.nix`)
2. Import it from `.config/nix/home-manager/default.nix`

If the tool needs raw config files rather than a `programs.<tool>` HM module, manage them as symlinks instead (see below).

## Add a dotfile symlink

Edit `.config/nix/home-manager/dotfiles.nix`:

- For `~/.config/<...>` files, append to the `configFiles` list
- For files at `$HOME`, add an entry to `home.file` using the `mkLink` helper defined in the same file

`mkLink` produces an out-of-store symlink back into this repo, so edits in the working tree are picked up without rebuilding.

## Add a new host

1. Create `.config/nix/hosts/<host>/default.nix` modeled on `hosts/personal/default.nix` or `hosts/work/default.nix`. It must:
   - Set `hostSpec.{hostName,username,isWork}`
   - Set `networking.hostName`, `system.primaryUser`, and `users.users.<username>`
   - Define host-specific `dr` / `drb` / `drc` shell aliases pointing at `--flake ...#<host>`
2. Add `<host> = darwin.lib.darwinSystem { inherit system; modules = [ ./hosts/<host> ] ++ commonModules; };` to `darwinConfigurations` in `.config/nix/flake.nix`
3. Apply with `sudo darwin-rebuild switch --flake .config/nix#<host>`

## Verify

Before committing:

```bash
sudo darwin-rebuild build --flake .config/nix#personal   # build only, no activation
nix flake check .config/nix
```

Build on the host you actually use; for cross-host changes, build both `personal` and `work` if possible.
