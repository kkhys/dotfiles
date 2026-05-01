# Architecture

How the flake composes a full nix-darwin + Home Manager system.

## Composition

`.config/nix/flake.nix` is the only entry point. It defines:

- A `commonModules` list — the system-wide module set shared by every host
- One `darwinConfigurations.<host>` per host, built as `[ ./hosts/<host> ] ++ commonModules`

`commonModules` includes (see `flake.nix` for the authoritative list and order):

- `./modules/host-spec.nix` — declares the `config.hostSpec` options
- `./hosts/common` — shared system packages and Homebrew package lists
- `./darwin` — system-level macOS settings, Nix settings, Homebrew toggles, agenix
- `agenix.darwinModules.default` — agenix integration
- `home-manager.darwinModules.home-manager` — Home Manager integration; `users.<username>` is set from `config.hostSpec.username` and imports `./home-manager`
- `nix-homebrew.darwinModules.nix-homebrew` — declarative Homebrew, also keyed off `config.hostSpec.username`

## hostSpec

`modules/host-spec.nix` declares three options used throughout the tree:

- `hostSpec.hostName` — networking hostname
- `hostSpec.username` — primary user; drives Home Manager home dir, Homebrew owner, secret decryption paths
- `hostSpec.isWork` — gates work-only packages and secrets via `lib.mkIf config.hostSpec.isWork`

Each `hosts/<host>/default.nix` sets these values. Other modules consume them via `config.hostSpec.*`.

## Module trees

- `darwin/default.nix` imports the rest of `darwin/` (system prefs, nix, homebrew settings, secrets)
- `home-manager/default.nix` imports `packages.nix`, `dotfiles.nix`, and everything under `programs/`
- `hosts/common/default.nix` imports the three `homebrew*.nix` package lists

Reading any of these `default.nix` files is the fastest way to see the current set of imports.

## Configuration flow

1. `darwin-rebuild switch --flake .config/nix#<host>` evaluates `darwinConfigurations.<host>`
2. The host module sets `hostSpec.*`, network hostname, `system.primaryUser`, and `users.users.<username>`
3. `commonModules` merges in system, user, Homebrew, and agenix configuration — all parameterized by `config.hostSpec.*`
4. nix-darwin activates system settings; Home Manager activates user settings; nix-homebrew reconciles Homebrew; agenix decrypts secrets to the paths declared in `darwin/secrets.nix`

Everything happens in a single atomic activation.

## Target

- System: `aarch64-darwin` (Apple Silicon only)
- Nix Flakes are required (experimental feature enabled in `darwin/nix.nix`)
