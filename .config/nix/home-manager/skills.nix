{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Agent skills kept latest on every rebuild the same way mise tools are:
  # fetch the latest via the skills CLI. Each entry is the skills registry
  # identifier. The CLI installs into ~/.agents/skills and links into
  # ~/.claude/skills.
  agentSkills = [
    "github/gh-stack"
    "github/gh-actions-lock"
  ];

  # Named explicitly: left to detect agents, `-y` also targets every agent
  # sharing ~/.agents/skills, including ones with no global skills dir
  # (PromptScript), and reports each of those as a failed install. Codex reads
  # ~/.agents/skills and sees the skills either way; only Claude Code needs a
  # link.
  skillAgents = [
    "claude-code"
    "codex"
  ];
in
{
  # Runs after miseInstall so node/npx (managed by mise) are available.
  home.activation.agentSkills = lib.hm.dag.entryAfter [ "miseInstall" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
    ${lib.concatMapStringsSep "\n" (pkg: ''
      echo "Installing ${pkg} skills..."
      ${pkgs.mise}/bin/mise exec -- npx --yes skills add ${pkg} -a ${toString skillAgents} -g -y \
        || echo "warning: ${pkg} skills install skipped (offline?)" >&2
    '') agentSkills}
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
}
