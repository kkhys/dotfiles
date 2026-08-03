{ config, lib, pkgs, ... }:

let
  # Agent skills kept latest on every rebuild the same way mise tools are:
  # fetch the latest via the skills CLI. Each entry is the skills registry
  # identifier plus the glob its installed skill directories match (used to
  # mirror them into ~/.codex/skills). Optional `skill` narrows a multi-skill
  # source down to a single skill.
  agentSkills = [
    {
      pkg = "github/gh-stack";
      glob = "gh-stack*";
    }
    {
      # Lets an agent drive the herdr CLI from inside its own pane: inspect
      # workspaces, run commands in siblings, wait on other agents. The skill
      # no-ops unless HERDR_ENV=1, so it stays inert outside herdr.
      pkg = "herdrdev/herdr";
      skill = "herdr";
      glob = "herdr";
    }
    {
      # Teaches the ax CLI installed in packages.nix. The glob is exact: `ax*`
      # would also sweep unrelated skills into ~/.codex/skills.
      pkg = "yusukebe/ax";
      glob = "ax";
    }
    {
      # Drives the hunk TUI installed in programs/hunk.nix over `hunk session`,
      # so review notes land on the diff itself instead of in the chat log. The
      # skill asks the user to open hunk when no session is running, so it stays
      # harmless if it fires without one.
      pkg = "modem-dev/hunk";
      skill = "hunk-review";
      glob = "hunk-review";
    }
    {
      # Runs a relentless interview (/grilling) to pressure-test a plan or
      # design before committing to it. Narrowed to this one skill since the
      # source repo bundles many unrelated skills.
      pkg = "mattpocock/skills";
      skill = "grill-me";
      glob = "grill-me";
    }
  ];

  skillFlag = s: lib.optionalString (s ? skill) "--skill ${s.skill} ";
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
