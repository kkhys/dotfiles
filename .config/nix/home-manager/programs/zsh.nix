{
  config,
  lib,
  hostSpec,
  ...
}:

let
  flakePath = "~/projects/github.com/kkhys/dotfiles/.config/nix";

  # Files come from darwin/secrets.nix; the -f guard keeps work-only secrets
  # inert on personal hosts.
  secretEnvVars = {
    NPM_TOKEN = "npm-token";
    GITHUB_ACCESS_TOKEN = "github-token";
    QASE_API_TOKEN = "qase-api-token";
  };
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    fastSyntaxHighlighting.enable = true;

    # One dump per zsh version: the Nix zsh (5.9.2) and /bin/zsh (5.9) would
    # otherwise take turns invalidating a shared ~/.zcompdump.
    completionInit = ''
      autoload -Uz compinit
      mkdir -p "${config.xdg.cacheHome}/zsh"
      compinit -d "${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
    '';

    history = {
      path = "${config.home.homeDirectory}/.config/zsh/.zsh_history";
      size = 10000;
      save = 10000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    zsh-abbr = {
      enable = true;
      abbreviations = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";

        dr = "sudo darwin-rebuild switch --flake ${flakePath}#${hostSpec.hostName}";
        drb = "sudo darwin-rebuild build --flake ${flakePath}#${hostSpec.hostName}";
        drc = "sudo darwin-rebuild check --flake ${flakePath}#${hostSpec.hostName}";

        cat = "bat";

        ls = "eza --group-directories-first";
        l = "eza -l --group-directories-first";
        la = "eza -a --group-directories-first";
        ll = "eza -l --git --group-directories-first";
        lla = "eza -la --git --group-directories-first";
        lt = "eza -T --git-ignore";
        "l." = "eza -d .*";

        v = "vim";
        g = "git";
        "z." = "zed .";
        cf = "caffeinate -id";

        np = "npm";
        pn = "pnpm";
        b = "bun";

        cl = "claude";
        yolo = "claude --dangerously-skip-permissions";

        cx = "codex";

        nfu = "nix flake update --flake ${flakePath}";

        gg = "ghq get";
        gl = "ghq list";
      };
    };

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

    initContent = lib.mkMerge [
      # Before compinit (Home Manager emits it at order 570). Anything that
      # reaches fpath later is missed by a fresh login shell but inherited by
      # nested ones, and that mismatch made compinit rewrite the dump on every
      # alternation between the two.
      (lib.mkOrder 550 ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # brew shellenv exports FPATH; keep fpath per-shell so child shells
        # rebuild it and see the same set compinit saw here.
        typeset +x FPATH

        # zsh-abbr is sourced after compinit, so register its completions early.
        fpath+=("${config.programs.zsh.zsh-abbr.package}/share/zsh/zsh-abbr/completions")
      '')
      ''
        export PATH="$HOME/.local/bin:$PATH"

        setopt HIST_REDUCE_BLANKS

        function repo() {
          local selected=$(ghq list | fzf --preview "bat --color=always --style=plain $(ghq root)/{}/README.md 2>/dev/null || ls -la $(ghq root)/{}")
          if [[ -n "$selected" ]]; then
            cd "$(ghq root)/$selected"
          fi
        }

        function get() {
          ghq get "$1" && cd "$(ghq root)/$(ghq list | grep -E "$(echo $1 | sed 's/.*[:/]//')" | head -1)"
        }
      ''
    ];
  };
}
