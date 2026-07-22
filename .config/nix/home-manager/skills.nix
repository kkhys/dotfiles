{ config, lib, pkgs, ... }:

{
  # Keep cmux agent skills up to date the same way mise tools are kept latest:
  # fetch the latest on every rebuild via the skills CLI. Runs after miseInstall
  # so node/npx (managed by mise) are available.
  home.activation.cmuxSkills = lib.hm.dag.entryAfter [ "miseInstall" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    echo "Installing cmux skills..."
    ${pkgs.mise}/bin/mise exec -- npx --yes skills add manaflow-ai/cmux -g -y \
      || echo "warning: cmux skills install skipped (offline?)" >&2
    # The skills CLI installs to ~/.agents/skills and links into ~/.claude/skills,
    # but not ~/.codex/skills. Mirror them so Codex picks them up too.
    if [ -d "$HOME/.agents/skills" ]; then
      mkdir -p "$HOME/.codex/skills"
      for skill in "$HOME"/.agents/skills/cmux*; do
        [ -e "$skill" ] || continue
        name="$(basename "$skill")"
        ln -sfn "../../.agents/skills/$name" "$HOME/.codex/skills/$name"
      done
    fi
  '';
}
