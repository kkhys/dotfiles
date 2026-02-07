{ config, hostSpec, ... }:

let
  flakePath = "~/projects/github.com/kkhys/dotfiles/.config/nix";
in
{
  programs.zsh = {
    enable = true;

    # History settings
    history = {
      path = "${config.home.homeDirectory}/.config/zsh/.zsh_history";
      size = 10000;
      save = 10000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    # Shell aliases (auto-expanded by Home Manager)
    shellAliases = {
      # Nix darwin-rebuild
      dr = "sudo darwin-rebuild switch --flake ${flakePath}#${hostSpec.hostName}";
      drb = "sudo darwin-rebuild build --flake ${flakePath}#${hostSpec.hostName}";
      drc = "sudo darwin-rebuild check --flake ${flakePath}#${hostSpec.hostName}";
      # Directory navigation
      ".." = "cd ..";
      "..." = "../../";
      "...." = "../../../";
      "....." = "../../../../";

      # File viewing (bat)
      cat = "bat";

      # File listing (eza)
      ls = "eza --group-directories-first";
      l = "eza -l --group-directories-first";
      la = "eza -a --group-directories-first";
      ll = "eza -l --git --group-directories-first";
      lla = "eza -la --git --group-directories-first";
      lt = "eza -T --git-ignore";
      "l." = "eza -d .*";

      # Tools
      v = "vim";
      g = "git";

      # Docker
      dc = "docker compose";
      de = "docker exec";

      # Package managers
      np = "npm";
      pn = "pnpm";
      b = "bun";

      # Claude
      cl = "claude";
      yolo = "claude --dangerously-skip-permissions";

      # Terminal
      z = "zellij";

      # Nix
      nfu = "nix flake update --flake ~/projects/github.com/kkhys/dotfiles/.config/nix";

      # ghq
      gg = "ghq get";
      gl = "ghq list";
    };

    # Environment variables (.zshenv)
    envExtra = ''
      export LANGUAGE="ja_JP.UTF-8"
      export LANG="''${LANGUAGE}"
      export LC_ALL="''${LANGUAGE}"
      export LC_CTYPE="''${LANGUAGE}"
      export DO_NOT_TRACK=1

      # Load NPM_TOKEN from agenix-decrypted secret (work environment only)
      if [[ -f "$HOME/.config/secrets/npm-token" ]]; then
        export NPM_TOKEN="$(cat $HOME/.config/secrets/npm-token)"
      fi

      # Load GITHUB_ACCESS_TOKEN from agenix-decrypted secret
      if [[ -f "$HOME/.config/secrets/github-token" ]]; then
        export GITHUB_ACCESS_TOKEN="$(cat $HOME/.config/secrets/github-token)"
      fi
    '';

    # .zshrc content (full control)
    initContent = ''
      # ----------------------------------------------------
      # Claude Code
      # ----------------------------------------------------
      export PATH="$HOME/.local/bin:$PATH"

      # ----------------------------------------------------
      # Homebrew
      # ----------------------------------------------------
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # ----------------------------------------------------
      # Options
      # ----------------------------------------------------
      setopt INC_APPEND_HISTORY
      setopt HIST_REDUCE_BLANKS
      setopt AUTO_PARAM_KEYS

      # ----------------------------------------------------
      # ghq + fzf
      # ----------------------------------------------------
      # Navigate to repository with fzf
      function repo() {
        local selected=$(ghq list | fzf --preview "bat --color=always --style=plain $(ghq root)/{}/README.md 2>/dev/null || ls -la $(ghq root)/{}")
        if [[ -n "$selected" ]]; then
          cd "$(ghq root)/$selected"
        fi
      }

      # Clone repository and cd into it
      function get() {
        ghq get "$1" && cd "$(ghq root)/$(ghq list | grep -E "$(echo $1 | sed 's/.*[:/]//')" | head -1)"
      }
    '';
  };
}
