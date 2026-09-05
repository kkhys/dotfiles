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
    DEVIN_API_KEY = "devin-api-key";
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
        ca = "cursor agent";
        cx = "codex";
        dv = "devin";

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
      # Copilot CLI permissions
      # ----------------------------------------------------
      # Mirror of the Claude Code permission tiers (.config/claude/settings.json).
      # Copilot has no persistent tool-permission config (settings.json only
      # carries allowedUrls/trustedFolders), so the tiers ride on flags:
      #   Claude allow -> --allow-tool   (enumerated; Copilot has no ask tier,
      #                   so Claude's ask list is simply left unlisted and
      #                   prompts, as do commands missing from the enumeration)
      #   Claude deny  -> --deny-tool    (blocks without prompting; wins over allow)
      # Read()-style denies are not expressible; Copilot confines reads to the
      # working directory instead. MCP rules use the server names from
      # plugins/mcp/.mcp.json in kkhys/claude-code-marketplace.
      function copilot() {
        command copilot \
          --allow-tool 'write' \
          --deny-tool 'write(.env)' \
          --deny-tool 'write(.envrc)' \
          --allow-all-urls \
          --allow-tool 'context7' \
          --allow-tool 'serena' \
          --deny-tool 'serena(execute_shell_command)' \
          --allow-tool 'playwright' \
          --allow-tool 'chrome-devtools' \
          --allow-tool 'astro-docs' \
          --allow-tool 'analytics-mcp' \
          --allow-tool 'shell(git status)' \
          --allow-tool 'shell(git diff)' \
          --allow-tool 'shell(git log)' \
          --allow-tool 'shell(git show)' \
          --allow-tool 'shell(git blame)' \
          --allow-tool 'shell(git add)' \
          --allow-tool 'shell(git commit)' \
          --allow-tool 'shell(git checkout)' \
          --allow-tool 'shell(git switch)' \
          --allow-tool 'shell(git restore)' \
          --allow-tool 'shell(git branch)' \
          --allow-tool 'shell(git stash)' \
          --allow-tool 'shell(git fetch)' \
          --allow-tool 'shell(git pull)' \
          --allow-tool 'shell(git merge)' \
          --allow-tool 'shell(git tag)' \
          --allow-tool 'shell(git remote)' \
          --allow-tool 'shell(git rev-parse)' \
          --allow-tool 'shell(git worktree)' \
          --allow-tool 'shell(gh pr view)' \
          --allow-tool 'shell(gh pr list)' \
          --allow-tool 'shell(gh pr diff)' \
          --allow-tool 'shell(gh pr checks)' \
          --allow-tool 'shell(gh pr status)' \
          --allow-tool 'shell(gh run view)' \
          --allow-tool 'shell(gh run list)' \
          --allow-tool 'shell(gh run watch)' \
          --allow-tool 'shell(gh issue view)' \
          --allow-tool 'shell(gh issue list)' \
          --allow-tool 'shell(gh api)' \
          --allow-tool 'shell(gh repo view)' \
          --allow-tool 'shell(gh search)' \
          --allow-tool 'shell(gh auth status)' \
          --deny-tool 'shell(gh repo delete)' \
          --deny-tool 'shell(gh auth logout)' \
          --deny-tool 'shell(gh secret delete)' \
          --deny-tool 'shell(gh variable delete)' \
          --allow-tool 'shell(npm install)' \
          --allow-tool 'shell(npm ci)' \
          --allow-tool 'shell(npm run)' \
          --allow-tool 'shell(npm test)' \
          --allow-tool 'shell(npm view)' \
          --allow-tool 'shell(npm ls)' \
          --allow-tool 'shell(pnpm install)' \
          --allow-tool 'shell(pnpm add)' \
          --allow-tool 'shell(pnpm run)' \
          --allow-tool 'shell(pnpm test)' \
          --allow-tool 'shell(pnpm list)' \
          --allow-tool 'shell(bun install)' \
          --allow-tool 'shell(bun run)' \
          --allow-tool 'shell(bun test)' \
          --allow-tool 'shell(npx:*)' \
          --allow-tool 'shell(uvx:*)' \
          --allow-tool 'shell(curl:*)' \
          --allow-tool 'shell(wget:*)' \
          --allow-tool 'shell(jq:*)' \
          --allow-tool 'shell(rg:*)' \
          --allow-tool 'shell(grep:*)' \
          --allow-tool 'shell(find:*)' \
          --allow-tool 'shell(fd:*)' \
          --allow-tool 'shell(ls:*)' \
          --allow-tool 'shell(eza:*)' \
          --allow-tool 'shell(cat:*)' \
          --allow-tool 'shell(bat:*)' \
          --allow-tool 'shell(head:*)' \
          --allow-tool 'shell(tail:*)' \
          --allow-tool 'shell(wc:*)' \
          --allow-tool 'shell(sed:*)' \
          --allow-tool 'shell(awk:*)' \
          --allow-tool 'shell(sort:*)' \
          --allow-tool 'shell(tr:*)' \
          --allow-tool 'shell(xargs:*)' \
          --allow-tool 'shell(mkdir:*)' \
          --allow-tool 'shell(cp:*)' \
          --allow-tool 'shell(mv:*)' \
          --allow-tool 'shell(touch:*)' \
          --allow-tool 'shell(which:*)' \
          --allow-tool 'shell(echo:*)' \
          --allow-tool 'shell(mise:*)' \
          --deny-tool 'shell(rm -rf)' \
          --deny-tool 'shell(rm -fr)' \
          --deny-tool 'shell(rm --recursive)' \
          --deny-tool 'shell(chmod 777)' \
          --deny-tool 'shell(chmod -R 777)' \
          --deny-tool 'shell(dd)' \
          --deny-tool 'shell(brew install)' \
          --deny-tool 'shell(brew uninstall)' \
          --deny-tool 'shell(brew bundle)' \
          --deny-tool 'shell(terraform apply)' \
          --deny-tool 'shell(terraform destroy)' \
          --deny-tool 'shell(terragrunt apply)' \
          --deny-tool 'shell(terragrunt destroy)' \
          --deny-tool 'shell(just apply)' \
          --deny-tool 'shell(aws s3 rm)' \
          --deny-tool 'shell(aws s3 rb)' \
          --deny-tool 'shell(aws ec2 terminate-instances)' \
          --deny-tool 'shell(aws rds delete-db-instance)' \
          --deny-tool 'shell(aws rds delete-db-cluster)' \
          --deny-tool 'shell(aws lambda delete-function)' \
          --deny-tool 'shell(aws cloudformation delete-stack)' \
          --deny-tool 'shell(aws dynamodb delete-table)' \
          --deny-tool 'shell(aws sns delete-topic)' \
          --deny-tool 'shell(aws sqs delete-queue)' \
          "$@"
      }

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
