{ lib, pkgs, ... }:

let
  tomlFormat = pkgs.formats.toml { };
in
{
  # hunk exports a home-manager module from its own flake, but consuming it
  # would add the flake (plus bun2nix and a source build) as inputs for what
  # amounts to one config file and two symlinks, so this stays on the `hunk`
  # already in nixpkgs.
  home.packages = [ pkgs.hunk ];

  xdg.configFile."hunk/config.toml".source = tomlFormat.generate "hunk-config.toml" {
    # Matches the Ghostty theme
    theme = "catppuccin-mocha";

    # Terminal width picks split vs stack
    mode = "auto";

    line_numbers = true;

    # Agent annotations are the reason hunk is here rather than a plain diff
    # pager, so they start visible instead of behind `a`
    agent_notes = true;
  };

  # The hunk-review skill ships inside the hunk package and `hunk skill path`
  # points at it ("Load or symlink that file in your coding agent to keep it
  # in sync across Hunk upgrades"), so the linked SKILL.md always matches the
  # installed binary. The skills CLI used to fetch the latest SKILL.md
  # instead, which documented subcommands the pinned binary rejected.
  home.activation.hunkSkill = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # One-time takeover from the skills CLI, which installed a real directory.
    if [ -e "$HOME/.agents/skills/hunk-review" ] && [ ! -L "$HOME/.agents/skills/hunk-review" ]; then
      rm -r "$HOME/.agents/skills/hunk-review"
    fi
    mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
    # Codex and Cursor discover skills in ~/.agents/skills.
    ln -sfn "$(dirname "$("${pkgs.hunk}/bin/hunk" skill path)")" "$HOME/.agents/skills/hunk-review"
    # Claude Code only reads ~/.claude/skills; relative on purpose, matching
    # the links the skills CLI maintains next to it.
    ln -sfn "../../.agents/skills/hunk-review" "$HOME/.claude/skills/hunk-review"
  '';
}
