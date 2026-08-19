# Architecture

How the flake composes a full nix-darwin + Home Manager system.

## Composition

`.config/nix/flake.nix` is the only entry point. It defines a `mkHost` helper and one `darwinConfigurations.<host> = mkHost "<host>"` per host. Every host system is built from the same four module trees:

- `./modules/host-spec.nix` — declares the `config.hostSpec` options and derives system identity (`networking.hostName`, `system.primaryUser`, `users.users.<username>`) from them
- `./hosts/<host>` — that host's `hostSpec` values plus its host-only Homebrew list
- `./hosts/common` — shared system packages and the shared Homebrew list
- `./darwin` — system-level configuration; each file also imports and wires the upstream module it configures:
  - `home-manager.nix` — Home Manager integration; `users.<username>` imports `./home-manager`
  - `homebrew.nix` — nix-homebrew (declarative, pinned taps) plus Homebrew activation settings
  - `secrets.nix` — agenix module, agenix CLI, and the table of managed secrets
  - `system.nix` / `nix.nix` / `codex.nix` — macOS prefs and activation, Nix settings and GC, managed Codex config

Flake inputs reach every darwin module via `specialArgs.inputs`, and every Home Manager module via `extraSpecialArgs` (`inputs` and `hostSpec`). Adding a host or an input never requires touching module wiring in `flake.nix`.

## hostSpec

`modules/host-spec.nix` declares three options used throughout the tree:

- `hostSpec.hostName` — networking hostname, also the `darwinConfigurations` attribute name
- `hostSpec.username` — primary user; drives Home Manager home dir, Homebrew owner, secret decryption paths
- `hostSpec.isWork` — gates work-only packages and secrets

The same module derives `networking.hostName`, `system.primaryUser`, and `users.users.<username>` from these values, so each `hosts/<host>/default.nix` only declares the `hostSpec` attrset (and imports its `homebrew.nix`).

## Module trees

- `darwin/default.nix` imports the rest of `darwin/`
- `home-manager/default.nix` imports `packages.nix`, `dotfiles.nix`, `skills.nix`, `mcp.nix`, and everything under `programs/`
- `hosts/common/default.nix` imports `homebrew.nix` (the shared package list)
- `hosts/<host>/default.nix` imports its own `homebrew.nix` (host-only packages)

Reading any of these `default.nix` files is the fastest way to see the current set of imports.

## Configuration flow

1. `darwin-rebuild switch --flake .config/nix#<host>` evaluates `darwinConfigurations.<host>`
2. The host module sets `hostSpec.*`; `modules/host-spec.nix` derives hostname and user settings from it
3. The shared module trees merge in system, user, Homebrew, and agenix configuration — all parameterized by `config.hostSpec.*`
4. nix-darwin activates system settings; Home Manager activates user settings; nix-homebrew reconciles Homebrew; agenix decrypts secrets to the paths declared in `darwin/secrets.nix`

Everything happens in a single atomic activation.

## Target

- System: `aarch64-darwin` (Apple Silicon only)
- Nix Flakes are required (experimental feature enabled in `darwin/nix.nix`)
- Formatting: `nixfmt-tree` via `nix fmt` (the flake's `formatter` output)
