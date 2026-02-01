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
sudo darwin-rebuild build --flake ~/projects/dotfiles/.config/nix#kkhys

# Check configuration without building
sudo darwin-rebuild check --flake ~/projects/dotfiles/.config/nix#kkhys
```

### Validation

```bash
# Check flake syntax and build
nix flake check .config/nix

# Show flake outputs
nix flake show .config/nix

# Update flake inputs
nix flake update --flake .config/nix
```

### Homebrew

Homebrew is managed declaratively via Nix. Packages are defined in:
- `.config/nix/darwin/homebrew.nix` - Basic settings and taps
- `.config/nix/hosts/common/homebrew.nix` - Common packages for all hosts
- `.config/nix/hosts/common/homebrew-personal.nix` - Personal-only packages
- `.config/nix/hosts/common/homebrew-work.nix` - Work-only packages

No manual `brew bundle` commands are needed. Homebrew packages are installed/updated automatically when you run `darwin-rebuild switch`.

## Architecture

### Flake Structure

```
.config/nix/flake.nix (entry point)
├── inputs: nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask
└── outputs: darwinConfigurations
    ├── kkhys  → darwin.lib.darwinSystem
    └── work   → darwin.lib.darwinSystem

commonModules (shared across all hosts):
├── modules/host-spec.nix  - Custom host specification options
├── darwin/                - nix-darwin system settings
│   ├── homebrew.nix       - Homebrew basic settings and taps
│   ├── system.nix         - macOS system preferences
│   └── nix.nix            - Nix configuration
├── home-manager/          - Home Manager modules (user-level)
│   ├── packages.nix       - Nix packages (bat, eza, vim, jq, deno, etc.)
│   ├── dotfiles.nix       - Symlink management
│   └── programs/          - Program-specific configurations
│       ├── bun.nix        - Bun JavaScript runtime
│       ├── fzf.nix        - Fuzzy finder integration
│       ├── gh.nix         - GitHub CLI
│       ├── ghostty.nix    - Ghostty terminal (Catppuccin Mocha)
│       ├── git.nix        - Git with GPG signing
│       ├── gpg.nix        - GnuPG and pinentry-mac
│       ├── lazygit.nix    - Lazygit TUI
│       ├── mise.nix       - mise version manager (Node.js, pnpm)
│       ├── sheldon.nix    - Zsh plugin manager
│       ├── ssh.nix        - SSH configuration
│       ├── starship.nix   - Starship prompt
│       ├── yazi.nix       - Yazi file manager
│       └── zsh.nix        - Zsh with history, aliases, environment
└── hosts/common/          - Common host settings
    ├── homebrew.nix       - Homebrew package definitions
    ├── homebrew-personal.nix
    └── homebrew-work.nix
```

### Module System

**host-spec Module** (`.config/nix/modules/host-spec.nix`):
- Defines custom options: `hostName`, `username`, `isWork`
- Used by host configurations to specify environment-specific settings
- Accessible in all modules via `config.hostSpec.*`

**Darwin Modules** (`.config/nix/darwin/`):
- `default.nix` - Imports all darwin sub-modules
- `homebrew.nix` - Homebrew basic settings (enable, autoUpdate, cleanup)
- `system.nix` - macOS system preferences, Touch ID for sudo, activation scripts
- `nix.nix` - Nix configuration (experimental features, unfree packages)

**Home Manager Modules** (`.config/nix/home-manager/`):
- `default.nix` - Imports all sub-modules, sets username/homeDirectory from hostSpec
- `packages.nix` - Declares Nix packages (ghq, gibo, lefthook, vim, uv, bat, eza, zellij, jq, deno)
- `dotfiles.nix` - Manages symlinks via `xdg.configFile` and `home.file`
- `programs/` - Individual program configurations:
  - `bun.nix` - Bun JavaScript runtime
  - `fzf.nix` - Fuzzy finder with shell integration
  - `gh.nix` - GitHub CLI configuration
  - `ghostty.nix` - Ghostty terminal settings (theme: Catppuccin Mocha)
  - `git.nix` - Git configuration with GPG signing, aliases, global ignores
  - `gpg.nix` - GnuPG configuration with pinentry-mac
  - `lazygit.nix` - Lazygit terminal UI for Git
  - `mise.nix` - mise version manager (Node.js, pnpm, npm tools)
  - `sheldon.nix` - Zsh plugin manager configuration
  - `ssh.nix` - SSH configuration
  - `starship.nix` - Starship cross-shell prompt
  - `yazi.nix` - Yazi terminal file manager
  - `zsh.nix` - Zsh with history, aliases, environment variables

**Host Configurations** (`.config/nix/hosts/`):
- Each host defines its `hostSpec` values, network hostname, and user configuration
- `common/` contains settings shared by all hosts
- Host-specific shell aliases (dr, drb, drc) point to their respective flake

### Configuration Flow

1. `flake.nix` creates darwinConfiguration using `darwin.lib.darwinSystem`
2. Each host module is combined with commonModules
3. commonModules includes:
   - `host-spec.nix` - Provides `config.hostSpec.*` to all modules
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
{ config, ... }:
{
  hostSpec = {
    hostName = "hostname";
    username = "username";
    isWork = false;
  };

  networking.hostName = config.hostSpec.hostName;
  system.primaryUser = config.hostSpec.username;

  users.users.${config.hostSpec.username} = {
    name = config.hostSpec.username;
    home = "/Users/${config.hostSpec.username}";
  };

  # Host-specific shell aliases
  home-manager.users.${config.hostSpec.username} = {
    programs.zsh.shellAliases = {
      dr = "sudo darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#newhost";
      drb = "sudo darwin-rebuild build --flake ~/projects/dotfiles/.config/nix#newhost";
      drc = "sudo darwin-rebuild check --flake ~/projects/dotfiles/.config/nix#newhost";
    };
  };
}
```

2. Add to `flake.nix`:
```nix
darwinConfigurations = {
  # ... existing hosts
  newhost = darwin.lib.darwinSystem {
    inherit system;
    modules = [ ./hosts/newhost ] ++ commonModules;
  };
};
```

### Adding Symlinks

Add in `.config/nix/home-manager/dotfiles.nix`:
```nix
# For XDG config files (.config/)
configFiles = [
  "tool-name/config.toml"
];

# For home directory files
home.file = {
  ".tool-config".source = mkLink ".tool-config";
};
```

The `mkLink` function creates out-of-store symlinks to `~/projects/dotfiles/`.

### Adding Nix Packages

Edit `.config/nix/home-manager/packages.nix`:
```nix
home.packages = with pkgs; [
  ripgrep
  fd
];
```

### Adding Homebrew Packages

**For all hosts** - Edit `.config/nix/hosts/common/homebrew.nix`:
```nix
homebrew = {
  brews = [ "package-name" ];
  casks = [ "application-name" ];
};
```

**For personal hosts only** - Edit `.config/nix/hosts/common/homebrew-personal.nix`:
```nix
homebrew = lib.mkIf (!config.hostSpec.isWork) {
  casks = [ "personal-app" ];
};
```

**For work hosts only** - Edit `.config/nix/hosts/common/homebrew-work.nix`:
```nix
homebrew = lib.mkIf config.hostSpec.isWork {
  casks = [ "slack" "zoom" ];
};
```

### Adding Program Configuration

For tools with Home Manager modules, create a new file in `.config/nix/home-manager/programs/`:
```nix
# programs/tool.nix
{ ... }:
{
  programs.tool = {
    enable = true;
    settings = {
      # configuration
    };
  };
}
```

Then import in `.config/nix/home-manager/default.nix`:
```nix
imports = [
  ./programs/tool.nix
  # ... other imports
];
```

## Host Configurations

### kkhys (Personal)
- `hostName`: "mini"
- `username`: "kkhys"
- `isWork`: false
- Additional packages: docker, Adobe Creative Cloud

### work
- `hostName`: "work"
- `username`: "keisuke.hayashi"
- `isWork`: true
- Additional packages: Colima, Microsoft Edge, OpenVPN Connect, oVice, Slack

## Nix Language Notes

- This repository uses Nix Flakes (experimental feature)
- Target system: `aarch64-darwin` (Apple Silicon)
- Nix files use attribute sets, `let...in` bindings, and lambda functions
- `config.hostSpec.*` is available in all modules via `modules/host-spec.nix`
- `lib.mkIf` for conditional configuration

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
