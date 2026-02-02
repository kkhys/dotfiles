# dotfiles

Personal macOS development environment configuration managed with Nix Flakes, nix-darwin, and Home Manager.

## Prerequisites

- macOS (Apple Silicon - aarch64-darwin)
- Git (pre-installed on macOS)
- Admin access (sudo privileges)
- Stable internet connection
- Age private key backup (for new machine setup)

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

Clone via HTTPS first (SSH keys are not yet available):

```bash
mkdir -p ~/projects/github.com/kkhys
git clone https://github.com/kkhys/dotfiles.git ~/projects/github.com/kkhys/dotfiles
cd ~/projects/github.com/kkhys/dotfiles
```

### 3. Backup Existing Configuration Files

```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

### 4. Restore Age Private Key

Restore the age private key from your backup (1Password, etc.):

```bash
mkdir -p ~/.config/age
# Create the key file and paste your age private key
vim ~/.config/age/keys.txt
chmod 600 ~/.config/age/keys.txt
```

The key looks like: `AGE-SECRET-KEY-1XXXXXX...`

This key is required to decrypt SSH and GPG keys during setup.

### 5. Apply Configuration

For personal environment:

```bash
sudo nix run \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  nix-darwin -- switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal
```

For work environment:

```bash
sudo nix run \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  nix-darwin -- switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#work
```

This takes 5-15 minutes on first run.

### 6. Switch Remote to SSH

After setup, SSH keys are available. Switch the remote URL to SSH:

```bash
cd ~/projects/github.com/kkhys/dotfiles
git remote set-url origin git@github.com:kkhys/dotfiles.git

# Verify
git remote -v
```

### 7. Restart Shell

```bash
exec zsh
```

## Usage

### Apply Configuration Changes

```bash
git add -A
sudo darwin-rebuild switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal

# Or use alias
dr
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
dr
```

### Update Dependencies

```bash
nfu  # nix flake update
dr
```

## Commands

```bash
# Apply configuration
dr

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

### Secrets Decryption Failed

```
error: Failed to decrypt ...
```

Solution: Ensure the age private key is correctly placed:

```bash
cat ~/.config/age/keys.txt
# Should start with AGE-SECRET-KEY-
chmod 600 ~/.config/age/keys.txt
```

## Important: Backup Your Age Private Key

The file `~/.config/age/keys.txt` is the **only key** that can decrypt your secrets. If lost, you cannot recover your SSH/GPG keys from the encrypted `.age` files.

**Backup locations (choose at least 2):**
- Password manager (1Password, Bitwarden)
- Encrypted USB drive
- Printed paper in secure location

The key is a single line starting with `AGE-SECRET-KEY-`.

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
│   ├── nix.nix            # Nix configuration
│   └── secrets.nix        # agenix decryption settings
├── secrets/               # Encrypted secrets (agenix)
│   ├── secrets.nix        # Age public keys
│   ├── ssh-key-github.age # Encrypted SSH private key
│   ├── gpg-key.age        # Encrypted GPG private key
│   └── id_ed25519_github.pub # SSH public key
├── home-manager/          # User-level configuration
│   ├── default.nix
│   ├── packages.nix       # Nix packages
│   ├── dotfiles.nix       # Symlink management
│   └── programs/          # Program-specific configurations
│       ├── bun.nix        # Bun JavaScript runtime
│       ├── fzf.nix        # Fuzzy finder
│       ├── gh.nix         # GitHub CLI
│       ├── ghostty.nix    # Ghostty terminal
│       ├── git.nix        # Git with GPG signing
│       ├── gpg.nix        # GnuPG configuration
│       ├── lazygit.nix    # Lazygit TUI
│       ├── mise.nix       # mise version manager
│       ├── sheldon.nix    # Zsh plugin manager
│       ├── ssh.nix        # SSH configuration
│       ├── starship.nix   # Starship prompt
│       ├── yazi.nix       # Yazi file manager
│       └── zsh.nix        # Zsh configuration
└── hosts/
    ├── common/            # Shared configuration
    │   ├── default.nix
    │   ├── homebrew.nix
    │   ├── homebrew-personal.nix
    │   └── homebrew-work.nix
    ├── personal/          # Personal machine
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
- Encrypted secrets decryption (agenix)

### Secrets (agenix)

- SSH private key (GitHub)
- GPG private key
- SSH public key

### User Level (Home Manager)

- Shell (Zsh with Sheldon plugin manager, Starship prompt)
- Git (config, GPG signing, global ignores)
- GitHub CLI
- Ghostty terminal
- Lazygit TUI
- mise (Node.js, pnpm, npm tools)
- Bun JavaScript runtime
- fzf fuzzy finder
- Yazi file manager
- SSH configuration
- GnuPG (gpg, pinentry-mac)
- Symlinks for Karabiner, Zellij, Zed, Claude

### Nix Packages

- Git Tools: ghq, gibo, lefthook
- Development: vim, uv, deno
- Terminal: bat, eza, zellij
- Data Processing: jq
