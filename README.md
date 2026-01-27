# dotfiles

Personal macOS development environment configuration managed with Nix Flakes, nix-darwin, and Home Manager.

## Prerequisites

- macOS (Apple Silicon - aarch64-darwin)
- Git (pre-installed on macOS)
- Admin access (sudo privileges)
- Stable internet connection

## Installation

### 1. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install)
```

Close and reopen your terminal, then enable flakes:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 2. Clone Repository

```bash
mkdir -p ~/projects
git clone https://github.com/kkhys/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
```

### 3. Backup Existing Configuration Files

```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

### 4. Apply Configuration

For personal environment:

```bash
sudo nix run \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  nix-darwin -- switch --flake ~/projects/dotfiles/.config/nix#kkhys
```

For work environment:

```bash
sudo nix run \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  nix-darwin -- switch --flake ~/projects/dotfiles/.config/nix#work
```

This takes 5-15 minutes on first run.

### 5. Restart Shell

```bash
exec zsh
```

## Usage

### Apply Configuration Changes

```bash
git add -A
sudo darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#kkhys

# Or use alias
sudo dr
```

### Add Packages

#### Homebrew Packages

Edit `.config/nix/hosts/common/homebrew.nix` (all hosts):

```nix
homebrew = {
  brews = [ "ripgrep" ];
  casks = [ "visual-studio-code" ];
};
```

Edit `.config/nix/hosts/common/homebrew-personal.nix` (personal only):

```nix
homebrew = lib.mkIf (!config.hostSpec.isWork) {
  casks = [ "discord" ];
};
```

Edit `.config/nix/hosts/common/homebrew-work.nix` (work only):

```nix
homebrew = lib.mkIf config.hostSpec.isWork {
  casks = [ "slack" "zoom" ];
};
```

#### Nix Packages

Edit `.config/nix/home-manager/packages.nix`:

```nix
home.packages = with pkgs; [
  ripgrep
  fd
];
```

Then apply:

```bash
git add -A
sudo dr
```

### Update Dependencies

```bash
nix flake update .config/nix
sudo dr
```

## Commands

```bash
# Apply configuration
sudo dr

# Build without activating
drb

# Check syntax
drc

# Rollback
sudo darwin-rebuild switch --rollback

# Clean up old generations
sudo nix-collect-garbage --delete-older-than 30d
```

## Troubleshooting

### Unexpected files in /etc

```
error: Unexpected files in /etc, aborting activation
```

Solution:

```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

### Path not tracked by Git

```
error: Path '.config/nix/...' is not tracked by Git
```

Solution:

```bash
git add -A
```

## Structure

```
.config/nix/
├── flake.nix              # Entry point
├── modules/
│   └── host-spec.nix      # Custom host options (hostName, username, isWork)
├── darwin/                # nix-darwin system settings
│   ├── default.nix
│   ├── homebrew.nix       # Homebrew settings and taps
│   ├── system.nix         # macOS preferences (Dock, Finder, etc.)
│   └── nix.nix            # Nix configuration
├── home-manager/          # User-level configuration
│   ├── default.nix
│   ├── packages.nix       # Nix packages
│   ├── dotfiles.nix       # Symlink management
│   ├── zsh.nix            # Zsh configuration
│   ├── git.nix            # Git configuration with GPG signing
│   ├── gh.nix             # GitHub CLI configuration
│   ├── ghostty.nix        # Ghostty terminal settings
│   └── mise.nix           # mise version manager settings
└── hosts/
    ├── common/            # Shared configuration
    │   ├── default.nix
    │   ├── homebrew.nix
    │   ├── homebrew-personal.nix
    │   └── homebrew-work.nix
    ├── kkhys/             # Personal machine
    │   └── default.nix
    └── work/              # Work machine
        └── default.nix
```

## What's Managed

### System Level (nix-darwin)

- macOS preferences (Dock, Finder, keyboard, trackpad)
- Homebrew packages (brews, casks)
- Touch ID for sudo
- Nix garbage collection

### User Level (Home Manager)

- Shell (Zsh with aliases, history, environment)
- Git (config, GPG signing, global ignores)
- GitHub CLI
- Ghostty terminal
- mise (Node.js, pnpm, npm tools)
- Symlinks for Karabiner, Zellij, Zed, Claude

### Nix Packages

- Development: git, gh, vim, uv, deno, bun
- Utilities: jq, zellij, gibo, lefthook
- Security: gnupg, pinentry_mac
