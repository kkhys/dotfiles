# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Nix Flakes + nix-darwin + Home Manager based dotfiles repository for managing macOS (Darwin) development environments. It supports multi-host configurations (personal and work) using a modular architecture with integrated Homebrew management via nix-homebrew.

## Common Commands

### Apply Configuration

```bash
# Initial setup (first time only)
sudo nix run \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  nix-darwin -- switch --flake ~/projects/dotfiles/.config/nix#kkhys

# After first setup (standard usage)
sudo darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#kkhys

# For work environment
sudo darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#work

# Build without activating (test configuration)
darwin-rebuild build --flake ~/projects/dotfiles/.config/nix#kkhys

# Check configuration without building
darwin-rebuild check --flake ~/projects/dotfiles/.config/nix#kkhys
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

Homebrew is now managed declaratively via Nix. Packages are defined in:
- `.config/nix/darwin/homebrew.nix` - Taps and basic settings
- `.config/nix/hosts/common/homebrew.nix` - Common packages for all hosts

No manual `brew bundle` commands are needed. Homebrew packages are installed/updated automatically when you run `darwin-rebuild switch`.

## Architecture

### Flake Structure

The Nix configuration uses a modular architecture centered around `flake.nix`:

```
.config/nix/flake.nix (entry point)
├── inputs: nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask
└── outputs: darwinConfigurations
    ├── kkhys  → darwin.lib.darwinSystem
    └── work   → darwin.lib.darwinSystem

commonModules (shared across all hosts):
├── modules/hostSpec.nix   - Custom host specification options
├── darwin/                - nix-darwin system settings
│   ├── homebrew.nix      - Homebrew basic settings and taps
│   ├── system.nix        - macOS system preferences
│   └── nix.nix          - Nix configuration
├── home-manager/          - Home Manager modules (user-level)
└── hosts/common/          - Common host settings
    └── homebrew.nix      - Homebrew package definitions
```

### Module System

**hostSpec Module** (`.config/nix/modules/hostSpec.nix`):
- Defines custom options: `hostName`, `username`, `isWork`
- Used by host configurations to specify environment-specific settings
- Accessible in all modules via `config.hostSpec.*`

**Darwin Modules** (`.config/nix/darwin/`):
- `default.nix` - Imports all darwin sub-modules
- `homebrew.nix` - Homebrew basic settings (enable, autoUpdate, cleanup, taps)
- `system.nix` - macOS system preferences (Dock, Finder, keyboard, trackpad, etc.)
- `nix.nix` - Nix configuration (experimental features, unfree packages)

**Home Manager Modules** (`.config/nix/home-manager/`):
- `default.nix` - Imports all sub-modules, sets username/homeDirectory from hostSpec
- `dotfiles.nix` - Manages symlinks via `xdg.configFile` and `home.file`
- `packages.nix` - Declares Nix packages (user-level)
- `zsh.nix` - Configures Zsh with history, aliases, environment variables

**Host Configurations** (`.config/nix/hosts/`):
- Each host defines its `hostSpec` values, network hostname, and user configuration
- `common/` contains settings shared by all hosts (system packages, Homebrew packages, GC settings)
- `common/homebrew.nix` - Common Homebrew brews and casks
- Host-specific overrides go in respective directories

### Configuration Flow

1. `flake.nix` creates darwinConfiguration using `darwin.lib.darwinSystem`
2. Each host module is combined with commonModules
3. commonModules includes:
   - `hostSpec.nix` - Provides `config.hostSpec.*` to all modules
   - `darwin/` - System-level macOS settings
   - `hosts/common/` - Shared system packages and Homebrew definitions
   - Home Manager integration - User-level settings
   - nix-homebrew integration - Declarative Homebrew management
4. `home-manager/default.nix` reads `config.hostSpec.username` to set user home directory
5. `nix-homebrew` uses `config.hostSpec.username` to manage Homebrew installation
6. All modules merge into final nix-darwin + Home Manager configuration
7. `darwin-rebuild switch` applies both system and user settings atomically

## Key Patterns

### Adding a New Host

1. Create `.config/nix/hosts/newhost/default.nix`:
```nix
{ config, pkgs, ... }:
{
  # hostSpec configuration
  hostSpec = {
    hostName = "hostname";
    username = "username";
    isWork = false;
  };

  # Hostname configuration
  networking.hostName = config.hostSpec.hostName;
  system.primaryUser = config.hostSpec.username;

  # User configuration
  users.users.${config.hostSpec.username} = {
    name = config.hostSpec.username;
    home = "/Users/${config.hostSpec.username}";
  };

  # Host-specific system packages
  environment.systemPackages = with pkgs; [
    # Add host-specific packages here
  ];
}
```

2. Add to `flake.nix`:
```nix
darwinConfigurations = {
  kkhys = darwin.lib.darwinSystem {
    inherit system;
    modules = [ ./hosts/kkhys ] ++ commonModules;
  };
  work = darwin.lib.darwinSystem {
    inherit system;
    modules = [ ./hosts/work ] ++ commonModules;
  };
  newhost = darwin.lib.darwinSystem {
    inherit system;
    modules = [ ./hosts/newhost ] ++ commonModules;
  };
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

### Adding Homebrew Packages

**For all hosts** - Edit `.config/nix/hosts/common/homebrew.nix`:
```nix
{ ... }:
{
  homebrew = {
    brews = [
      "package-name"
    ];

    casks = [
      "application-name"
    ];
  };
}
```

**For personal hosts only** (isWork = false) - Edit `.config/nix/hosts/common/homebrew-personal.nix`:
```nix
{ config, lib, ... }:
{
  homebrew = lib.mkIf (!config.hostSpec.isWork) {
    brews = [
      "personal-tool"
    ];

    casks = [
      "personal-app"
    ];
  };
}
```

**For work hosts only** (isWork = true) - Edit `.config/nix/hosts/common/homebrew-work.nix`:
```nix
{ config, lib, ... }:
{
  homebrew = lib.mkIf config.hostSpec.isWork {
    brews = [
      "work-tool"
    ];

    casks = [
      "slack"
      "zoom"
    ];
  };
}
```

**For custom taps** - Edit `.config/nix/darwin/homebrew.nix`:
```nix
{ ... }:
{
  homebrew = {
    taps = [
      "user/tap-name"
    ];
  };
}
```

After editing, run `sudo darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#kkhys` to apply changes.

## Nix Language Notes

- This repository uses Nix Flakes (experimental feature)
- Target system: `aarch64-darwin` (Apple Silicon)
- Nix files use attribute sets, `let...in` bindings, and lambda functions
- `config.hostSpec.*` is available in all modules via `modules/hostSpec.nix`

## Key Technologies

- **nix-darwin**: Manages macOS system configuration declaratively
- **Home Manager**: Manages user-level configuration (dotfiles, packages)
- **nix-homebrew**: Integrates Homebrew with Nix for declarative package management
- **Nix Flakes**: Provides reproducible builds and dependency management

## Differences from Home Manager-only Setup

| Aspect | Home Manager Only | nix-darwin + Home Manager |
|--------|------------------|--------------------------|
| **Scope** | User-level only | System + User level |
| **Command** | `home-manager switch` | `darwin-rebuild switch` |
| **Homebrew** | Manual management | Declarative via nix-homebrew |
| **System Settings** | Not managed | Managed (Dock, Finder, etc.) |
| **Requires sudo** | No | Yes (for system changes) |
| **Configuration Type** | homeConfigurations | darwinConfigurations |
