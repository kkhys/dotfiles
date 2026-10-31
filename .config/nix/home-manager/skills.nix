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
}
