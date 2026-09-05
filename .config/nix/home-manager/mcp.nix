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
#   Copilot CLI  copilot plugin install + update mcp@my-marketplace

let
  # Homebrew casks are not on PATH during activation.
  copilot = "/opt/homebrew/bin/copilot";
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

    # Copilot CLI. marketplace add fails once the marketplace is registered,
    # install is idempotent, update refreshes an existing install.
    if [ -x "${copilot}" ]; then
      "${copilot}" plugin marketplace add kkhys/claude-code-marketplace >/dev/null 2>&1 || true
      if "${copilot}" plugin install mcp@my-marketplace >/dev/null 2>&1 \
        && "${copilot}" plugin update mcp >/dev/null 2>&1; then
        echo "Copilot: mcp@my-marketplace installed"
      else
        echo "warning: Copilot mcp plugin install skipped (offline or not logged in?)" >&2
      fi
    fi
  '';
}
