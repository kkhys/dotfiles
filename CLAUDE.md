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
  nix-darwin -- switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal

# After first setup (standard usage)
sudo darwin-rebuild switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal

# For work environment
sudo darwin-rebuild switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#work

# Build without activating (test configuration)
sudo darwin-rebuild build --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal

# Check configuration without building
sudo darwin-rebuild check --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal
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
├── inputs: nixpkgs, darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask, agenix
└── outputs: darwinConfigurations
    ├── personal  → darwin.lib.darwinSystem
    └── work      → darwin.lib.darwinSystem

commonModules (shared across all hosts):
├── modules/host-spec.nix  - Custom host specification options
├── darwin/                - nix-darwin system settings
│   ├── homebrew.nix       - Homebrew basic settings and taps
│   ├── system.nix         - macOS system preferences
│   ├── nix.nix            - Nix configuration
│   └── secrets.nix        - agenix secrets decryption settings
├── secrets/               - Encrypted secrets (agenix)
│   ├── secrets.nix        - Age public keys and secret file definitions
│   ├── ssh-key-github.age - Encrypted SSH private key
│   ├── gpg-key.age        - Encrypted GPG private key
│   ├── npm-token.age      - Encrypted NPM token (work environment only)
│   └── id_ed25519_github.pub - SSH public key (not encrypted)
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
- `secrets.nix` - agenix configuration (decryption paths, identity paths)

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
   - agenix integration - Encrypted secrets management
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
      dr = "sudo darwin-rebuild switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#newhost";
      drb = "sudo darwin-rebuild build --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#newhost";
      drc = "sudo darwin-rebuild check --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#newhost";
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

The `mkLink` function creates out-of-store symlinks to `~/projects/github.com/kkhys/dotfiles/`.

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

### personal
- `hostName`: "personal"
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
- **agenix**: Manages encrypted secrets (SSH/GPG keys) that can be safely committed to Git

## Secrets Management (agenix)

### Overview

SSH and GPG private keys are encrypted with age and stored in the repository. They are automatically decrypted during `darwin-rebuild switch`.

### Files

| File | Description |
|------|-------------|
| `~/.config/age/keys.txt` | Age private key (NOT in repo, must backup separately) |
| `secrets/secrets.nix` | Age public key definitions |
| `secrets/ssh-key-github.age` | Encrypted SSH private key |
| `secrets/gpg-key.age` | Encrypted GPG private key |
| `secrets/npm-token.age` | Encrypted NPM token (work environment only) |
| `secrets/id_ed25519_github.pub` | SSH public key (not encrypted) |
| `darwin/secrets.nix` | Decryption configuration |

### New Machine Setup

1. Restore the age private key from backup (1Password, etc.):
```bash
mkdir -p ~/.config/age
# Paste the age private key into ~/.config/age/keys.txt
chmod 600 ~/.config/age/keys.txt
```

2. Run `darwin-rebuild switch` - secrets are automatically decrypted

### Adding New Secrets

1. Edit `secrets/secrets.nix` to define the new secret file:
```nix
{
  "new-secret.age".publicKeys = allKeys;
}
```

2. Encrypt the secret:
```bash
cd ~/projects/github.com/kkhys/dotfiles/.config/nix
nix-shell -p age --run "age -r <age-public-key> -o secrets/new-secret.age /path/to/secret"
```

3. Add decryption config in `darwin/secrets.nix`:
```nix
age.secrets.new-secret = {
  file = "${secretsPath}/new-secret.age";
  path = "/path/to/decrypted/secret";
  owner = username;
  mode = "600";
};
```

4. Stage and apply:
```bash
git add secrets/new-secret.age
sudo darwin-rebuild switch --flake .#personal
```

### Re-encrypting Secrets

If you need to change the age key or add new recipients:

```bash
cd ~/projects/github.com/kkhys/dotfiles/.config/nix

# Decrypt and re-encrypt SSH key
nix-shell -p age --run "age -d -i ~/.config/age/keys.txt secrets/ssh-key-github.age | age -r <new-age-public-key> -o secrets/ssh-key-github.age.new"
mv secrets/ssh-key-github.age.new secrets/ssh-key-github.age
```

### Environment-Specific Secrets

Some secrets are only decrypted on specific environments using `config.hostSpec.isWork`:

```nix
# darwin/secrets.nix
(lib.mkIf (npmTokenExists && config.hostSpec.isWork) {
  npm-token = {
    file = "${secretsPath}/npm-token.age";
    path = "/Users/${username}/.config/secrets/npm-token";
    owner = username;
    mode = "600";
  };
})
```

The decrypted secret is loaded as an environment variable in `zsh.nix`:

```nix
# Load NPM_TOKEN from agenix-decrypted secret (work environment only)
if [[ -f "$HOME/.config/secrets/npm-token" ]]; then
  export NPM_TOKEN="$(cat $HOME/.config/secrets/npm-token)"
fi
```

## Differences from Home Manager-only Setup

| Aspect | Home Manager Only | nix-darwin + Home Manager |
|--------|------------------|--------------------------|
| **Scope** | User-level only | System + User level |
| **Command** | `home-manager switch` | `darwin-rebuild switch` |
| **Homebrew** | Manual management | Declarative via nix-homebrew |
| **System Settings** | Not managed | Managed (Dock, Finder, etc.) |
| **Requires sudo** | No | Yes (for system changes) |
| **Configuration Type** | homeConfigurations | darwinConfigurations |
