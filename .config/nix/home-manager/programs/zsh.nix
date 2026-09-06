{
  config,
  lib,
  hostSpec,
  ...
}:

let
  flakePath = "~/projects/github.com/kkhys/dotfiles/.config/nix";

  # Env vars backed by agenix-decrypted files (declared in darwin/secrets.nix).
  # The runtime -f guard keeps work-only secrets inert on personal hosts.
  secretEnvVars = {
    NPM_TOKEN = "npm-token";
    GITHUB_ACCESS_TOKEN = "github-token";
    QASE_API_TOKEN = "qase-api-token";
    SONARQUBE_TOKEN = "sonarqube-token";
  };
in
{
  programs.zsh = {
    enable = true;

    # One dump per zsh version: the Nix zsh (5.9.2) and /bin/zsh (5.9) would
    # otherwise take turns invalidating a shared ~/.zcompdump.
    completionInit = ''
      autoload -Uz compinit
      mkdir -p "${config.xdg.cacheHome}/zsh"
      compinit -d "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
    '';

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

    # Abbreviations (auto-expand on space/enter, visible in history)
    zsh-abbr = {
      enable = true;
      abbreviations = {
        # Directory navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";

        # Nix darwin-rebuild
        dr = "sudo darwin-rebuild switch --flake ${flakePath}#${hostSpec.hostName}";
        drb = "sudo darwin-rebuild build --flake ${flakePath}#${hostSpec.hostName}";
        drc = "sudo darwin-rebuild check --flake ${flakePath}#${hostSpec.hostName}";

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
        "z." = "zed .";
        cf = "caffeinate -id";

        # Diff review (hunk). Preferred over routing git through `hunk pager`:
        # the native loader also picks up untracked files and supports --watch
        hd = "hunk diff";
        hs = "hunk show";

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

        # AI coding agents
        cx = "codex";

        # Terminal
        h = "herdr";

        # Nix
        nfu = "nix flake update --flake ${flakePath}";

        # ghq
        gg = "ghq get";
        gl = "ghq list";
      };
    };

    # Environment variables (.zshenv)
    envExtra = ''
      export LANGUAGE="ja_JP.UTF-8"
      export LANG="''${LANGUAGE}"
      export LC_ALL="''${LANGUAGE}"
      export LC_CTYPE="''${LANGUAGE}"
    ''
    + lib.concatStrings (
      lib.mapAttrsToList (var: file: ''
        if [[ -f "$HOME/.config/secrets/${file}" ]]; then
          export ${var}="$(cat "$HOME/.config/secrets/${file}")"
        fi
      '') secretEnvVars
    );

    # .zshrc content (full control)
    initContent = lib.mkMerge [
      # Runs before compinit (Home Manager emits compinit at order 570).
      # Everything that contributes to fpath must land here; anything added
      # later is invisible to compinit in a fresh login shell but inherited by
      # nested shells, and that mismatch made compinit rewrite the dump on
      # every alternation between the two (about 1s, several when cold).
      (lib.mkOrder 550 ''
        # ----------------------------------------------------
        # Homebrew
        # ----------------------------------------------------
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # brew shellenv exports FPATH; keep fpath per-shell so child shells
        # rebuild it from scratch and see the same set compinit saw here.
        typeset +x FPATH

        # zsh-abbr is sourced after compinit, so register its completions early.
        fpath+=("${config.programs.zsh.zsh-abbr.package}/share/zsh/zsh-abbr/completions")
      '')
      ''
        # ----------------------------------------------------
        # Claude Code
        # ----------------------------------------------------
        export PATH="$HOME/.local/bin:$PATH"

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
      ''
    ];
  };
}
