# dotfiles

My personal dotfiles collection

## Overview

This repository contains the following configurations:

- **Shell configuration** (`.zshrc`) - aliases, history management, path settings
- **Git configuration** (`.gitconfig`) - aliases, multi-environment support, GPG signing
- **Package management** (`.Brewfile`) - Homebrew packages, VSCode extensions
- **Claude Code configuration** (`.claude/`) - development AI settings
- **Other configurations** (`.config/`) - application-specific settings
- **Nix configuration** (`nix/`, `flake.nix`) - declarative system and user environment management

## 🚀 Quick Start

### Option A: 従来の管理（sync.sh）

## Setup

### 1. Clone Repository

```bash
git clone https://github.com/kkhys/dotfiles.git

cd dotfiles
```

### 2. Install Packages

```bash
# Install packages using Homebrew
brew bundle --file=.Brewfile
```

### 3. Sync Configurations

```bash
# Grant execute permission to sync script
chmod +x sync.sh

# Check current differences
./sync.sh status

# Sync from repository to home directory
./sync.sh to-home
```

## Sync Script Usage

The `sync.sh` script automates configuration file synchronization:

### Basic Commands

```bash
# Check differences (default)
./sync.sh
./sync.sh status

# Sync from home directory to repository
./sync.sh from-home

# Sync from repository to home directory
./sync.sh to-home

# Show help
./sync.sh help
```

### Features

- **Diff display**: Detailed colorized change visualization
- **Error handling**: Safe operations with detailed logging
- **Git integration**: Automatic git status display after changes

### Target Files

- `.zshrc` - Shell configuration
- `.gitconfig` - Git configuration
- `.Brewfile` - Package management
- `.claude/claude.md` - Claude Code configuration
- `.config/git/ignore` - Global Git ignore patterns
- `.config/github-copilot/intellij/global-copilot-instructions.md` - GitHub Copilot instructions
- `.config/github-copilot/intellij/global-git-commit-instructions.md` - Git commit guidelines
- `.config/github-copilot/intellij/mcp.json` - MCP server configuration

## Daily Usage

### After Configuration Changes

1. Modify configurations in home directory
2. Check differences with sync script: `./sync.sh status`
3. Sync to repository: `./sync.sh from-home`
4. Commit changes: `git add . && git commit -m "feat(config): update shell aliases"`

### New Environment Setup

1. Clone this repository
2. Install packages with `brew bundle`
3. Apply configurations with `./sync.sh to-home`
4. Enable settings with `exec $SHELL`

## Key Configuration Contents

### Shell (.zshrc)

- **High-efficiency aliases**: `cl=claude`, `g=git`, `dc=docker compose`
- **History optimization**: Duplicate removal, space ignoring
- **Development environment integration**: Bun, Deno, Node.js
- **Japanese support**: UTF-8 locale settings

### Git (.gitconfig)

- **Security**: Required GPG signing
- **Productivity enhancement**: `ps`/`pl` for current branch push/pull
- **Multi-environment**: Conditional configuration for work/private
- **Advanced aliases**: History search, interactive operations

### Packages (.Brewfile)

- **Development tools**: gh, git, gnupg, vim
- **Modern runtimes**: rustup, uv, bun, deno
- **VSCode extensions**: Astro, Biome, Tailwind, GitHub integration

## Troubleshooting

### Sync Errors

```bash
# Use Git to restore previous version
git checkout HEAD~1 -- .zshrc

# Force sync (use with caution)
rm ~/.zshrc && ./sync.sh to-home
```

### Permission Errors

```bash
# Grant execute permission to script
chmod +x sync.sh
```

## 🆕 Nix管理（実験的）

zshrcをNixで管理する実験中。詳細は[NIX.md](./NIX.md)を参照。

## License

MIT License - See [license.md](license.md) for details
