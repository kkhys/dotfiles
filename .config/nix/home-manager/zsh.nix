{ config, lib, pkgs, ... }:

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
      # Directory navigation
      ".." = "cd ..";
      "..." = "../../";
      "...." = "../../../";
      "....." = "../../../../";

      # File operations
      l = "less";
      la = "ls -aF";
      ll = "ls -l";
      lla = "ls -alF";
      "l." = "ls -d .[a-zA-Z]*";

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
    };

    # Environment variables (.zshenv)
    envExtra = ''
      export LANGUAGE="ja_JP.UTF-8"
      export LANG="''${LANGUAGE}"
      export LC_ALL="''${LANGUAGE}"
      export LC_CTYPE="''${LANGUAGE}"

      export PATH="$HOME/.local/share/mise/shims:$PATH"
    '';

    # .zshrc content (full control)
    initContent = ''
      # ----------------------------------------------------
      # Options
      # ----------------------------------------------------
      setopt INC_APPEND_HISTORY
      setopt HIST_REDUCE_BLANKS
      setopt AUTO_PARAM_KEYS

      # ----------------------------------------------------
      # mise
      # ----------------------------------------------------
      if type mise &>/dev/null; then
        eval "$(mise activate zsh)"
      fi
    '';
  };
}
