# dotfiles

Personal macOS development environment configuration managed with Nix Flakes and Home Manager.

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

### 3. Apply Configuration

For personal environment:
```bash
nix run home-manager/master -- switch --flake .config/nix#kkhys
```

For work environment:
```bash
nix run home-manager/master -- switch --flake .config/nix#work
```

### 4. Install Homebrew Packages (Optional)

```bash
brew bundle --file=.Brewfile
```

## Update Configuration

```bash
home-manager switch --flake ~/projects/dotfiles/.config/nix#kkhys
```

## License

MIT License - see [LICENSE.md](LICENSE.md) for details.
