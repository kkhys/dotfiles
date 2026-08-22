{
  config,
  lib,
  pkgs,
  hostSpec,
  ...
}:

let
  dotfilesPath = "${config.home.homeDirectory}/projects/github.com/kkhys/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";

  # XDG config files (under .config/)
  configFiles = [
    "karabiner/karabiner.json"
    "zed/settings.json"
  ];

  # AI agent configs: .config/<tool>/<file> in this repo -> ~/.<tool>/<file>.
  # Codex's config.toml is deliberately absent: Codex rewrites ~/.codex/config.toml
  # in place (project trust levels, feature toggles, TUI state), so it cannot be
  # a symlink into this repo. The managed settings ship through Codex's system
  # config layer instead; see darwin/codex.nix.
  agentFiles = {
    claude = [
      "CLAUDE.md"
      "statusline-command.sh"
    ];
    codex = [ "AGENTS.md" ];
    copilot = [ "copilot-instructions.md" ];
    gemini = [ "settings.json" ];
  };

  claudeSettingsFile = if hostSpec.isWork then "settings-work.json" else "settings.json";
in
{
  xdg.configFile = lib.genAttrs configFiles (file: {
    source = mkLink ".config/${file}";
  });

  home.file =
    lib.concatMapAttrs (
      tool: files:
      lib.listToAttrs (
        map (file: {
          name = ".${tool}/${file}";
          value.source = mkLink ".config/${tool}/${file}";
        }) files
      )
    ) agentFiles
    // {
      # Claude settings (host-specific: personal uses settings.json, work uses settings-work.json)
      ".claude/settings.json".source = mkLink ".config/claude/${claudeSettingsFile}";
      # SSH public key
      ".ssh/id_ed25519_github.pub".source = mkLink ".config/nix/secrets/id_ed25519_github.pub";
    };

  home.activation = {
    # The managed Codex settings live in /etc/codex/config.toml, which is the
    # LOWEST-precedence layer. A key left over in ~/.codex/config.toml silently
    # shadows it, so warn instead of letting the two drift apart unnoticed.
    # Codex's own runtime keys ([projects], [notice], tui.model_availability_nux)
    # are expected there and are not managed by this repo.
    codexConfigShadowCheck = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      userConfig="$HOME/.codex/config.toml"
      systemConfig="/etc/codex/config.toml"
      if [ -f "$userConfig" ] && [ -f "$systemConfig" ]; then
        # Flatten a TOML file to one sorted "section.key" line per assignment,
        # so [tui] holding only Codex's own model_availability_nux does not read
        # as a conflict with the tui.theme we manage.
        flattenToml() {
          ${pkgs.gawk}/bin/awk '
            /^[[:space:]]*#/ { next }
            /^[[:space:]]*\[/ { section = $0; gsub(/^[[:space:]]*\[+|\]+[[:space:]]*$/, "", section); next }
            /^[[:space:]]*[A-Za-z_][A-Za-z0-9_-]*[[:space:]]*=/ {
              key = $1
              print (section == "" ? key : section "." key)
            }
          ' "$1" | ${pkgs.coreutils}/bin/sort -u
        }
        shadowed=$(${pkgs.coreutils}/bin/comm -12 \
          <(flattenToml "$userConfig") <(flattenToml "$systemConfig"))
        if [ -n "$shadowed" ]; then
          echo "warning: $userConfig shadows settings managed in $systemConfig:" >&2
          echo "$shadowed" | ${pkgs.gnused}/bin/sed 's/^/  /' >&2
          echo "  The user layer wins. Remove those keys to let the managed values apply." >&2
        fi
      fi
    '';
  }
  // lib.optionalAttrs hostSpec.isWork {
    # Docker CLI plugins symlinks (work environment only)
    # Uses activation script because Homebrew binaries may not exist at build time
    dockerCliPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.docker/cli-plugins"
      if [ -f "/opt/homebrew/opt/docker-compose/bin/docker-compose" ]; then
        ln -sfn "/opt/homebrew/opt/docker-compose/bin/docker-compose" "$HOME/.docker/cli-plugins/docker-compose"
      fi
      if [ -f "/opt/homebrew/opt/docker-buildx/bin/docker-buildx" ]; then
        ln -sfn "/opt/homebrew/opt/docker-buildx/bin/docker-buildx" "$HOME/.docker/cli-plugins/docker-buildx"
      fi
    '';
  };
}
