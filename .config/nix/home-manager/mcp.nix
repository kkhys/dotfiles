{
  config,
  lib,
  pkgs,
  hostSpec,
  ...
}:

# One MCP server list for every agent. The list lives in the plugin
# marketplace as plugins/mcp/.mcp.json (Claude Code plugin format) and reaches
# each agent the way that agent can consume it:
#
#   Claude Code  enabledPlugins in ~/.claude/settings.json (dotfiles.nix)
#   Codex        codex plugin add mcp@my-marketplace (git marketplace, auto-upgrades at startup)
#   Copilot CLI  copilot plugin install + update mcp@my-marketplace
#   Devin CLI    devin plugins install <checkout>/plugins/mcp --local (live link)   work host only
#   Cursor       ~/.cursor/mcp.json generated below                                 work host only
#
# Devin and Cursor are work tools (hosts/work/homebrew.nix), so their steps
# are gated on hostSpec.isWork.
#
# Cursor has no plugin path for a Claude-format .mcp.json, so its file is
# rendered from it with jq.

let
  # Same checkout skills.nix links the skills from.
  marketplace = "${config.home.homeDirectory}/projects/github.com/kkhys/claude-code-marketplace";
  mcpJson = "${marketplace}/plugins/mcp/.mcp.json";
  jq = "${pkgs.jq}/bin/jq";
  timeout = "${pkgs.coreutils}/bin/timeout";
  # Homebrew casks are not on PATH during activation.
  copilot = "/opt/homebrew/bin/copilot";
  devin = "/opt/homebrew/bin/devin";
in
{
  # After miseInstall so the mise-managed codex is present, and after
  # marketplaceSkills so a missing checkout is reported once, there.
  home.activation.agentMcp = lib.hm.dag.entryAfter [ "marketplaceSkills" ] ''
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

    ${lib.optionalString hostSpec.isWork ''
      if [ ! -f "${mcpJson}" ]; then
        echo "warning: ${mcpJson} missing; Devin and Cursor MCP config not updated" >&2
      else
        # Devin CLI. --local links the checkout on this machine only; without it
        # Devin would add a local path to the account-wide plugin list, which
        # cloud sessions cannot reach. Needs `devin auth login`; the CLI has
        # hung without a TTY before, hence stdin closed and a timeout.
        if [ -x "${devin}" ]; then
          if ${timeout} 60 "${devin}" plugins install "${marketplace}/plugins/mcp" --local -y </dev/null >/dev/null 2>&1; then
            echo "Devin: mcp plugin linked"
          else
            echo "warning: Devin mcp plugin install skipped (run \`devin auth login\`?)" >&2
          fi
        fi

        # Cursor. Same shape as Claude Code minus the type key; url is enough
        # for a remote server. The file is owned by this activation: servers
        # added from Cursor's own UI are replaced on the next rebuild.
        mkdir -p "$HOME/.cursor"
        ${jq} '{mcpServers: (.mcpServers | map_values(del(.type)))}' "${mcpJson}" > "$HOME/.cursor/mcp.json"
        echo "Cursor: mcp.json rendered from ${mcpJson}"
      fi
    ''}
  '';
}
