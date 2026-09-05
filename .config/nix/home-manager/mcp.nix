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
}
