# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix Flakes + Home Manager based dotfiles repository for managing macOS (Darwin) development environments. It supports multi-host configurations (personal and work) using a modular architecture.

## Common Commands

### Apply Configuration

```bash
# Initial setup (first time)
nix run home-manager/master -- switch --flake .config/nix#kkhys

# After first setup
home-manager switch --flake ~/projects/dotfiles/.config/nix#kkhys

# For work environment
home-manager switch --flake ~/projects/dotfiles/.config/nix#work
```

### Validation

```bash
# Check flake syntax and build
nix flake check .config/nix

# Show flake outputs
nix flake show .config/nix

# Update flake inputs
nix flake update .config/nix
```

### Homebrew

```bash
# Install packages from Brewfile
brew bundle --file=.Brewfile

# Check what would be installed
brew bundle check --file=.Brewfile
```

## Architecture

### Flake Structure

The Nix configuration uses a modular architecture centered around `flake.nix`:

```
.config/nix/flake.nix (entry point)
├── inputs: nixpkgs, home-manager
└── outputs: homeConfigurations
    ├── kkhys  → mkHomeConfiguration ./hosts/kkhys
    └── work   → mkHomeConfiguration ./hosts/work

commonModules (shared across all hosts):
├── modules/hostSpec.nix   - Custom host specification options
├── home-manager/          - Home Manager modules
└── hosts/common/          - Common host settings
```

### Module System

**hostSpec Module** (`.config/nix/modules/hostSpec.nix`):
- Defines custom options: `hostName`, `username`, `isWork`
- Used by host configurations to specify environment-specific settings

**Home Manager Modules** (`.config/nix/home-manager/`):
- `default.nix` - Imports all sub-modules, sets username/homeDirectory from hostSpec
- `dotfiles.nix` - Manages symlinks via `xdg.configFile` and `home.file`
- `packages.nix` - Declares Nix packages (currently commented out)
- `zsh.nix` - Configures Zsh with history, aliases, environment variables

**Host Configurations** (`.config/nix/hosts/`):
- Each host defines its `hostSpec` values
- `common/` contains settings shared by all hosts
- Host-specific overrides go in respective directories

### Configuration Flow

1. `flake.nix` creates homeConfiguration by calling `mkHomeConfiguration`
2. `mkHomeConfiguration` combines: host module + commonModules
3. commonModules imports `hostSpec.nix`, enabling access to `config.hostSpec.*`
4. `home-manager/default.nix` reads `config.hostSpec.username` to set home directory
5. All modules merge into final Home Manager configuration

## Key Patterns

### Adding a New Host

1. Create `.config/nix/hosts/newhost/default.nix`:
```nix
{ config, pkgs, ... }:

{
  hostSpec = {
    hostName = "hostname";
    username = "username";
    isWork = false;
  };
}
```

2. Add to `flake.nix`:
```nix
homeConfigurations = {
  kkhys = mkHomeConfiguration ./hosts/kkhys;
  work = mkHomeConfiguration ./hosts/work;
  newhost = mkHomeConfiguration ./hosts/newhost;
};
```

### Adding Symlinks

Uncomment/add in `.config/nix/home-manager/dotfiles.nix`:
```nix
xdg.configFile = {
  "zed".source = mkLink ".config/zed";
};
```

The `mkLink` function creates out-of-store symlinks to `~/projects/dotfiles/`.

## Nix Language Notes

- This repository uses Nix Flakes (experimental feature)
- Target system: `aarch64-darwin` (Apple Silicon)
- Nix files use attribute sets, `let...in` bindings, and lambda functions
- `config.hostSpec.*` is available in all modules via `modules/hostSpec.nix`
