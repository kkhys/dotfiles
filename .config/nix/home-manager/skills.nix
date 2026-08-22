{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Agent skills kept latest on every rebuild the same way mise tools are:
  # fetch the latest via the skills CLI. Each entry is the skills registry
  # identifier; optional `skill` narrows a multi-skill source down to a single
  # skill. The CLI installs into ~/.agents/skills and links into ~/.claude/skills.
  agentSkills = [
    {
      pkg = "github/gh-stack";
    }
    {
      # Lets an agent drive the herdr CLI from inside its own pane: inspect
      # workspaces, run commands in siblings, wait on other agents. The skill
      # no-ops unless HERDR_ENV=1, so it stays inert outside herdr.
      pkg = "herdrdev/herdr";
      skill = "herdr";
    }
    {
      # Teaches the ax CLI installed in packages.nix.
      pkg = "yusukebe/ax";
    }
  ];

  skillFlag = s: lib.optionalString (s ? skill) "--skill ${s.skill} ";

  # Working tree of the plugin marketplace, not Claude Code's clone of it
  # (~/.claude/plugins/marketplaces/my-marketplace): the links below must not
  # depend on Claude Code's cache layout, and seeing work-in-progress skills in
  # the other agents is accepted. mcp.nix reads the same checkout.
  marketplace = "${config.home.homeDirectory}/projects/github.com/kkhys/claude-code-marketplace";
in
{
  # Runs after miseInstall so node/npx (managed by mise) are available.
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "miseInstall" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    ${lib.concatMapStringsSep "\n" (s: ''
      echo "Installing ${s.pkg} skills..."
      ${pkgs.mise}/bin/mise exec -- npx --yes skills add ${s.pkg} ${skillFlag s}-g -y \
        || echo "warning: ${s.pkg} skills install skipped (offline?)" >&2
    '') agentSkills}
    # Codex reads ~/.agents/skills directly, and Cursor reads ~/.codex/skills
    # as a compatibility path, so the mirror this file used to maintain in
    # ~/.codex/skills is harmful rather than redundant: a mirrored entry wins
    # Codex's realpath dedup and hides the real locator, and Cursor lists every
    # mirrored skill twice. Drop the links the mirror created; Codex's own
    # .system directory is untouched.
    if [ -d "$HOME/.codex/skills" ]; then
      for link in "$HOME"/.codex/skills/*; do
        [ -L "$link" ] || continue
        case "$(readlink "$link")" in
          ../../.agents/skills/*) rm "$link" ;;
        esac
      done
    fi
  '';

  # Expose every skill in the marketplace to the agents that read
  # ~/.agents/skills: Codex, Gemini CLI, Cursor, Devin and Copilot CLI. Claude
  # Code gets the same skills through the installed base plugin and does not
  # read ~/.agents/skills, so nothing is listed twice there. Codex namespaces
  # a symlinked skill by its canonical path, so these show up as base:<name>.
  home.activation.marketplaceSkills = lib.hm.dag.entryAfter [ "agentSkills" ] ''
    if [ ! -d "${marketplace}/plugins" ]; then
      echo "warning: ${marketplace} not checked out; marketplace skills not linked" >&2
    else
      mkdir -p "$HOME/.agents/skills"
      # A link into the marketplace whose skill was renamed or deleted.
      for link in "$HOME"/.agents/skills/*; do
        [ -L "$link" ] || continue
        case "$(readlink "$link")" in
          "${marketplace}"/*) [ -e "$link" ] || rm "$link" ;;
        esac
      done
      for dir in "${marketplace}"/plugins/*/skills/*/; do
        # Gemini only globs SKILL.md one level deep and drops anything without
        # it, so a directory that is not a skill must not be linked at all.
        [ -f "$dir/SKILL.md" ] || continue
        name="$(basename "$dir")"
        target="$HOME/.agents/skills/$name"
        # A real directory here is a skill the skills CLI installed; never
        # replace it, the two would otherwise fight on every rebuild.
        if [ -e "$target" ] && [ ! -L "$target" ]; then
          echo "warning: $target is a real directory; not linking the marketplace skill over it" >&2
          continue
        fi
        ln -sfn "''${dir%/}" "$target"
      done
    fi
  '';
}
