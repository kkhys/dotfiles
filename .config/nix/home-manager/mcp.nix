{
  config,
  lib,
  pkgs,
  ...
}:

# One MCP server list for every agent. The list lives in the plugin
# marketplace as plugins/mcp/.mcp.json (Claude Code plugin format) and reaches
# each agent the way that agent can consume it:
#
#   Claude Code  enabledPlugins in ~/.claude/settings.json (dotfiles.nix)
#   Codex        codex plugin add mcp@my-marketplace (git marketplace, auto-upgrades at startup)
#   Pi           ~/.pi/agent/mcp.json, copied from the marketplace checkout. The servers
#                of the other plugins enabled in Claude Code are registered at run time
#                by .config/pi/extensions/claude-compat, on top of this file

let
  # Working tree of the plugin marketplace; skills.nix explains why this and
  # not Claude Code's clone of it.
  marketplace = "${config.home.homeDirectory}/projects/github.com/kkhys/claude-code-marketplace";
in
{
  # After miseInstall so the mise-managed codex is present.
  home.activation.agentMcp = lib.hm.dag.entryAfter [ "miseInstall" ] ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"

    # Codex. Both commands are idempotent: a registered marketplace answers
    # alreadyAdded, a repeated add re-copies the current version. Codex records
    # the result in ~/.codex/config.toml ([marketplaces.*], [plugins.*]), which
    # is its user layer and not managed here.
    if ${pkgs.mise}/bin/mise exec -- codex plugin marketplace add kkhys/claude-code-marketplace >/dev/null 2>&1 \
      && ${pkgs.mise}/bin/mise exec -- codex plugin add mcp@my-marketplace >/dev/null 2>&1; then
      echo "Codex: mcp@my-marketplace installed"
    else
      echo "warning: Codex mcp plugin install skipped (offline or codex missing?)" >&2
    fi
  '';

  # Pi reads the mcpServers shape Claude Code plugins use, so the plugin's
  # .mcp.json is delivered unchanged. A copy rather than a link: `/mcp` and
  # `pi mcp add` write to this file, and those writes must not land in the
  # marketplace. They last until the next switch, which restores the list.
  home.activation.piMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    managed="${marketplace}/plugins/mcp/.mcp.json"
    target="$HOME/.pi/agent/mcp.json"
    if [ ! -f "$managed" ]; then
      echo "warning: ${marketplace} not checked out; Pi MCP servers not synced" >&2
    elif ! ${pkgs.diffutils}/bin/cmp -s "$managed" "$target"; then
      ${pkgs.coreutils}/bin/install -D -m 0644 "$managed" "$target"
    fi
  '';
}
