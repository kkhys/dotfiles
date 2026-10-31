{
  inputs,
  lib,
  ...
}:

let
  skills = {
    gh-stack = "${inputs.skills-gh-stack}/skills/gh-stack";
    gh-actions-lock = "${inputs.skills-gh-actions-lock}/skills/gh-actions-lock";
  };

  # Codex reads ~/.agents/skills; Claude Code only looks in ~/.claude/skills.
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
    # Leftovers of `npx skills add`: real directories under ~/.agents/skills,
    # relative links under ~/.claude/skills and the CLI's lock file. Home Manager
    # would keep the directories as <name>.backup, which Codex loads as duplicate
    # skills, and refuses the links outright.
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
      # Links of a former mirror in ~/.codex/skills: a mirrored entry wins Codex's
      # realpath dedup and hides the real locator. .system is Codex's own.
      if [ -d "$HOME/.codex/skills" ]; then
        for link in "$HOME"/.codex/skills/*; do
          [ -L "$link" ] || continue
          case "$(readlink "$link")" in
            ../../.agents/skills/*) rm "$link" ;;
          esac
        done
      fi
      # Links into the claude-code-marketplace checkout; Claude Code reaches it
      # as an installed plugin now and Codex no longer uses it.
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
