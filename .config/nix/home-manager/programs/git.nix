{ hostSpec, ... }:

{
  programs.git = {
    enable = true;

    signing = {
      key = "76CE0B6DCAA73B7FDF6DCACE72B1E765559945ED";
      signByDefault = true;
      format = "openpgp";
      signer = "/etc/profiles/per-user/${hostSpec.username}/bin/gpg";
    };

    ignores = [
      ".DS_Store"
      "**/.claude/settings.local.json"
      ".serena"
      ".playwright-mcp"
    ];

    settings = {
      user = {
        name = "kkhys";
        email = "kkhys@pm.me";
      };

      alias = {
        d = "diff";
        co = "checkout";
        ci = "commit";
        ca = "commit -a";
        ps = "!git push origin $(git rev-parse --abbrev-ref HEAD)";
        pl = "!git pull origin $(git rev-parse --abbrev-ref HEAD)";
        st = "status";
        br = "branch";
        ba = "branch -a";
        bm = "branch --merged";
        bn = "branch --no-merged";
        us = "reset --soft HEAD^";
        c1 = "commit --allow-empty -m 'chore: initialize feature branch'";
      };

      core = {
        quotepath = false;
        autocrlf = "input";
        ignorecase = false;
      };

      color = {
        status = "auto";
        diff = "auto";
        branch = "auto";
        interactive = "auto";
        grep = "auto";
        ui = "auto";
      };

      credential = {
        helper = "osxkeychain";
      };

      push = {
        default = "current";
      };

      pull = {
        ff = "only";
        rebase = false;
      };

      merge = {
        ff = false;
      };

      url = {
        "https://" = {
          insteadOf = "git://";
        };
      };

      github = {
        user = "kkhys";
      };

      ghq = {
        root = "~/projects";
      };
    };
  };
}
