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

  # Working tree of the plugin marketplace, not Claude Code's clone of it
  # (~/.claude/plugins/marketplaces/my-marketplace): the links below must not
  # depend on Claude Code's cache layout, and seeing work-in-progress skills in
  # Codex is accepted.
  marketplace = "${config.home.homeDirectory}/projects/github.com/kkhys/claude-code-marketplace";
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
  '';

  # Expose every skill in the marketplace to the agents that read
  # ~/.agents/skills: Codex. Claude Code gets
  # the same skills through the installed base plugin and does not read
  # ~/.agents/skills, so nothing is listed twice there. Codex namespaces a
  # symlinked skill by its canonical path, so these show up as base:<name>.
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
