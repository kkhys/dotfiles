{
  inputs,
  lib,
  ...
}:

let
  # Third-party agent skills, pinned through flake inputs the same way the
  # Homebrew taps are. Each value is the directory holding the skill's SKILL.md.
  skills = {
    gh-stack = "${inputs.skills-gh-stack}/skills/gh-stack";
    gh-actions-lock = "${inputs.skills-gh-actions-lock}/skills/gh-actions-lock";
  };

  # Codex reads ~/.agents/skills directly; Claude Code only looks in
  # ~/.claude/skills, so it gets its own link to the same store path.
  skillDirs = [
    ".agents/skills"
    ".claude/skills"
  ];
in
{
  home.file = lib.listToAttrs (
    lib.concatMap (
      dir: lib.mapAttrsToList (name: path: lib.nameValuePair "${dir}/${name}" { source = path; }) skills
    ) skillDirs
  );

  home.activation = {
    # These skills used to be installed by `npx skills add` on every rebuild,
    # which left real directories under ~/.agents/skills, relative links under
    # ~/.claude/skills and the CLI's lock file. Home Manager would move the
    # directories aside as <name>.backup, which Codex then loads as duplicate
    # skills, and it refuses the links outright, so clear that footprint before
    # the collision check.
    agentSkillsMigration = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      skillsMigrated=
      ${lib.concatMapStringsSep "\n" (name: ''
        if [ -d "$HOME/.agents/skills/${name}" ] && [ ! -L "$HOME/.agents/skills/${name}" ] \
          && [ -f "$HOME/.agents/skills/${name}/SKILL.md" ]; then
          run rm -r "$HOME/.agents/skills/${name}"
          skillsMigrated=1
        fi
        if [ -L "$HOME/.claude/skills/${name}" ] \
          && [ "$(readlink "$HOME/.claude/skills/${name}")" = "../../.agents/skills/${name}" ]; then
          run rm "$HOME/.claude/skills/${name}"
          skillsMigrated=1
        fi
      '') (lib.attrNames skills)}
      if [ -n "$skillsMigrated" ]; then
        run rm -f "$HOME/.agents/.skill-lock.json"
      fi
    '';

    agentSkillsCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Codex reads ~/.agents/skills directly, so the mirror this file used to
      # maintain in ~/.codex/skills is harmful rather than redundant: a mirrored
      # entry wins Codex's realpath dedup and hides the real locator. Drop the
      # links the mirror created; Codex's own .system directory is untouched.
      if [ -d "$HOME/.codex/skills" ]; then
        for link in "$HOME"/.codex/skills/*; do
          [ -L "$link" ] || continue
          case "$(readlink "$link")" in
            ../../.agents/skills/*) rm "$link" ;;
          esac
        done
      fi
      # This file used to link every skill of the claude-code-marketplace
      # checkout into ~/.agents/skills for Codex. The marketplace is Claude Code
      # only again and reaches it as an installed plugin, so drop those links.
      if [ -d "$HOME/.agents/skills" ]; then
        for link in "$HOME"/.agents/skills/*; do
          [ -L "$link" ] || continue
          case "$(readlink "$link")" in
            "$HOME"/projects/github.com/kkhys/claude-code-marketplace/*) rm "$link" ;;
          esac
        done
      fi
    '';
  };
}
