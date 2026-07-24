{ config, lib, pkgs, ... }:

let
  # Agent skills kept latest on every rebuild the same way mise tools are:
  # fetch the latest via the skills CLI. Each entry is the skills registry
  # identifier plus the glob its installed skill directories match (used to
  # mirror them into ~/.codex/skills).
  agentSkills = [
    {
      pkg = "manaflow-ai/cmux";
      glob = "cmux*";
    }
    {
      pkg = "github/gh-stack";
      glob = "gh-stack*";
    }
  ];
in
{
  # Runs after miseInstall so node/npx (managed by mise) are available.
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "miseInstall" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    ${lib.concatMapStringsSep "\n" (s: ''
      echo "Installing ${s.pkg} skills..."
      ${pkgs.mise}/bin/mise exec -- npx --yes skills add ${s.pkg} -g -y \
        || echo "warning: ${s.pkg} skills install skipped (offline?)" >&2
    '') agentSkills}
    # The skills CLI installs to ~/.agents/skills and links into ~/.claude/skills,
    # but not ~/.codex/skills. Mirror them so Codex picks them up too.
    if [ -d "$HOME/.agents/skills" ]; then
      mkdir -p "$HOME/.codex/skills"
      for glob in ${lib.concatMapStringsSep " " (s: s.glob) agentSkills}; do
        for skill in "$HOME"/.agents/skills/$glob; do
          [ -e "$skill" ] || continue
          name="$(basename "$skill")"
          ln -sfn "../../.agents/skills/$name" "$HOME/.codex/skills/$name"
        done
      done
    fi
  '';
}
