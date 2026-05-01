# dotfiles

Personal macOS (Apple Silicon) environment, fully declarative via Nix Flakes + nix-darwin + Home Manager. System settings, user packages, Homebrew, and secrets all live under `.config/nix/`. Two host outputs are defined: `personal` and `work`.

## Requirements

- macOS on Apple Silicon (`aarch64-darwin`)
- Admin (sudo) access
- Age private key backup (1Password / encrypted USB / paper) — required to decrypt SSH and GPG keys on a new machine

## Bootstrap a new machine

### 1. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install)
```

Reopen the terminal, then enable flakes:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### 2. Clone over HTTPS

SSH keys aren't decrypted yet, so clone via HTTPS for now:

```bash
mkdir -p ~/projects/github.com/kkhys
git clone https://github.com/kkhys/dotfiles.git ~/projects/github.com/kkhys/dotfiles
cd ~/projects/github.com/kkhys/dotfiles
```

### 3. Move pre-existing shell rc files aside

nix-darwin refuses to activate if it finds these files:

```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc  /etc/zshrc.before-nix-darwin
```

### 4. Restore the age private key

```bash
mkdir -p ~/.config/age
$EDITOR ~/.config/age/keys.txt    # paste the AGE-SECRET-KEY-... line
chmod 600 ~/.config/age/keys.txt
```

Without this, agenix can't decrypt SSH/GPG/API tokens during activation. See [agent_docs/secrets.md](agent_docs/secrets.md) for the full secrets workflow.

### 5. First activation

```bash
sudo nix run \
  --extra-experimental-features 'nix-command flakes' \
  nix-darwin -- switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal
```

Use `#work` on the work host. Initial run takes 5–15 minutes.

### 6. Switch the remote to SSH and reload the shell

```bash
git remote set-url origin git@github.com:kkhys/dotfiles.git
exec zsh
```

## Daily use

After the first activation, the active host exposes shell aliases that wrap `darwin-rebuild`:

```bash
dr     # switch  — apply (sudo darwin-rebuild switch  ...)
drb    # build   — build only, no activation
drc    # check   — eval/syntax check
nfu    # nix flake update
```

Typical change loop:

```bash
# edit any file under .config/nix/
git add -A          # untracked files must be staged for the flake to see them
dr
```

Other useful commands:

```bash
sudo darwin-rebuild switch --rollback              # revert to previous generation
sudo nix-collect-garbage --delete-older-than 30d   # prune old generations
```

## Where things live

```
.config/nix/
├── flake.nix              entry point — defines darwinConfigurations.{personal,work}
├── modules/host-spec.nix  declares config.hostSpec.{hostName,username,isWork}
├── darwin/                system: macOS prefs, Nix, Homebrew, agenix
├── home-manager/
│   ├── packages.nix       user-level Nix packages
│   ├── dotfiles.nix       symlinks back into this repo
│   └── programs/          one file per tool (zsh, git, gh, ghostty, ...)
├── hosts/
│   ├── common/            shared system + Homebrew package lists
│   ├── personal/          personal host overrides
│   └── work/              work host overrides
└── secrets/               agenix-encrypted secrets + recipient list
```

For task-specific deep dives:

- [agent_docs/architecture.md](agent_docs/architecture.md) — module composition, `hostSpec` flow, activation order
- [agent_docs/extending.md](agent_docs/extending.md) — adding a host, package, dotfile, or program module
- [agent_docs/secrets.md](agent_docs/secrets.md) — agenix workflow: new machine, new secret, key rotation

For new program modules under `home-manager/programs/`, the closest existing module in that directory is the best reference — match its structure rather than improvising.

Homebrew is fully declarative via nix-homebrew. Never run `brew bundle` or `brew install` manually — packages added that way will be removed on the next activation.

## What's managed

System (nix-darwin):
- macOS preferences (Dock, Finder, keyboard, trackpad, Touch ID for sudo)
- Homebrew formulae and casks (per-host scoped via `hostSpec.isWork`)
- Nix garbage collection
- agenix secret decryption

User (Home Manager):
- Shell — zsh, sheldon (plugin manager), starship (prompt)
- Git stack — git (with GPG signing), gh, lazygit
- Terminal — ghostty, zellij, bat, eza
- Editors / runtimes — vim, mise, bun, deno, rustup, python3 + uv + pipx
- Workflow — fzf, yazi, direnv, ssh, gpg + pinentry-mac
- Cloud — google-cloud-sdk; (work) colima
- Symlinks — Karabiner, Zellij, Zed, Claude, Gemini CLI, Codex

Secrets (agenix, see `secrets/secrets.nix` for the full list):
- SSH and GPG private keys
- GitHub token, NPM token (work)
- Qase, SonarQube, Devin API tokens

## Troubleshooting

`Unexpected files in /etc, aborting activation`

```bash
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc  /etc/zshrc.before-nix-darwin
```

`Path '.config/nix/...' is not tracked by Git` — flakes ignore untracked files. Stage them:

```bash
git add -A
```

`Failed to decrypt ...` — the age private key is missing or has wrong permissions:

```bash
ls -l ~/.config/age/keys.txt   # must exist, mode 600, start with AGE-SECRET-KEY-
chmod 600 ~/.config/age/keys.txt
```

## Back up the age private key

`~/.config/age/keys.txt` is the only key that decrypts every `*.age` file in this repo. If lost, all secrets are unrecoverable. Keep at least two backups (password manager + offline copy).
