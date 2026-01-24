# dotfiles

Personal macOS development environment configuration managed with Nix Flakes, nix-darwin, and Home Manager.

## Prerequisites

- macOS (Apple Silicon - aarch64-darwin)
- [Nix](https://nixos.org/download.html) with flakes enabled

## Setup

### 1. Install Nix

```bash
# Install Nix (multi-user installation)
sh <(curl -L https://nixos.org/nix/install)

# Enable flakes
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 2. Clone Repository

```bash
git clone https://github.com/kkhys/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
```

### 3. Apply Configuration (First Time)

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

This will:
- Install and configure nix-darwin
- Set up Home Manager
- Configure system settings (Zsh, Touch ID for sudo)
- Set up Homebrew with nix-homebrew (declarative package management)
- Install Xcode Command Line Tools if needed
- Install Rosetta 2 if needed (Apple Silicon)

## Update Configuration

After the initial setup, use the simpler command:

```bash
# For personal environment
sudo darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#kkhys

# For work environment
sudo darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#work
```

## Managing Homebrew Packages

Homebrew packages are managed declaratively through Nix configuration files:
- `.config/nix/hosts/common/homebrew.nix` - Common packages for all hosts
- `.config/nix/hosts/common/homebrew-personal.nix` - Personal-only packages (isWork = false)
- `.config/nix/hosts/common/homebrew-work.nix` - Work-only packages (isWork = true)

No manual `brew install` or `brew bundle` commands are needed.

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.
