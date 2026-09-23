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
  # config layer instead; see darwin/codex.nix. Its rules/managed.rules is
  # copied by the codexRulesSync activation below, not linked.
  agentFiles = {
    claude = [
      "CLAUDE.md"
      "statusline-command.sh"
    ];
    codex = [
      "AGENTS.md"
    ];
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
    # Execpolicy mirror of the Claude permission tiers. Codex enumerates
    # ~/.codex/rules/*.rules with DirEntry::file_type(), which does not follow
    # symlinks, so a Home Manager link there is silently skipped and every
    # escalation keeps prompting; the file has to be a regular file. Codex's
    # own TUI-added allows land in default.rules next to it, so the two never
    # collide. Runs after linkGeneration so the symlink from the earlier
    # home.file delivery is cleaned up before the copy lands.
    codexRulesSync = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      managed=${../../codex/rules/managed.rules}
      target="$HOME/.codex/rules/managed.rules"
      if [ -L "$target" ] || ! ${pkgs.diffutils}/bin/cmp -s "$managed" "$target"; then
        ${pkgs.coreutils}/bin/install -D -m 0644 "$managed" "$target"
      fi
    '';

    # The managed Codex settings live in /etc/codex/config.toml, which is the
    # LOWEST-precedence layer. A key left over in ~/.codex/config.toml silently
    # shadows it, so warn instead of letting the two drift apart unnoticed.
    # Codex's own runtime keys ([projects], [notice], tui.model_availability_nux)
    # and the /model selection (model, model_reasoning_effort) are expected there
    # and are not managed by this repo.
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

    # Devin permission mirror (devin-cli is a work-host cask). Devin rewrites
    # ~/.config/devin/config.json in place for its own runtime state (org_id,
    # model choice, Orca hooks, "always allow" grants), so the file cannot be a
    # symlink into this repo, and its system.json layer only accepts login and
    # proxy policy. Replace just the permissions block instead. Entries Devin
    # saved there that the managed file does not list are reported so they can
    # be ported into .config/devin/permissions.json if still wanted.
    devinPermissionsSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      managed=${../../devin/permissions.json}
      userConfig="$HOME/.config/devin/config.json"
      jq=${pkgs.jq}/bin/jq
      mkdir -p "$(dirname "$userConfig")"
      [ -f "$userConfig" ] || (umask 077; echo '{}' > "$userConfig")
      if ! "$jq" -e . "$userConfig" >/dev/null 2>&1; then
        echo "warning: $userConfig is not valid JSON; Devin permissions were not synced" >&2
      else
        dropped=$("$jq" -r --slurpfile m "$managed" '
          def rules: [ (.permissions // {}) | to_entries[] | .key as $tier | .value[] | "\($tier): \(.)" ];
          (rules - ($m[0] | rules))[]
        ' "$userConfig")
        if [ -n "$dropped" ]; then
          echo "warning: dropping Devin permission entries not in .config/devin/permissions.json:" >&2
          echo "$dropped" | ${pkgs.gnused}/bin/sed 's/^/  /' >&2
        fi
        tmp=$(${pkgs.coreutils}/bin/mktemp "$userConfig.XXXXXX")
        "$jq" --slurpfile m "$managed" '.permissions = $m[0].permissions' "$userConfig" > "$tmp"
        if ${pkgs.diffutils}/bin/cmp -s "$tmp" "$userConfig"; then
          rm -f "$tmp"
        else
          mv "$tmp" "$userConfig"
        fi
      fi
    '';

    # Cursor permission mirror (Cursor is a work-host cask). The CLI owns
    # ~/.cursor/cli-config.json (model picker, auth cache, self-repair via temp
    # file + rename), so as with Devin the file cannot be a symlink; only its
    # permissions block and the WebSearch auto-accept flag are replaced. `~/`
    # in Read()/Write() tokens is expanded because the username differs per
    # host and Cursor does not document tilde expansion.
    cursorPermissionsSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      managed=${../../cursor/permissions.json}
      userConfig="$HOME/.cursor/cli-config.json"
      jq=${pkgs.jq}/bin/jq
      prelude='
        def rules: [ (.permissions // {}) | to_entries[] | .key as $tier | .value[] | "\($tier): \(.)" ];
        def expand: map(sub("^(?<kind>Read|Write)\\(~/"; "\(.kind)(\($home)/"));
        ($m[0] | map_values(expand)) as $want |
      '
      mkdir -p "$(dirname "$userConfig")"
      [ -f "$userConfig" ] || (umask 077; echo '{"version":1}' > "$userConfig")
      if ! "$jq" -e . "$userConfig" >/dev/null 2>&1; then
        echo "warning: $userConfig is not valid JSON; Cursor permissions were not synced" >&2
      else
        dropped=$("$jq" -r --slurpfile m "$managed" --arg home "$HOME" \
          "$prelude"' (rules - ({ permissions: $want } | rules))[]' "$userConfig")
        if [ -n "$dropped" ]; then
          echo "warning: dropping Cursor permission entries not in .config/cursor/permissions.json:" >&2
          echo "$dropped" | ${pkgs.gnused}/bin/sed 's/^/  /' >&2
        fi
        tmp=$(${pkgs.coreutils}/bin/mktemp "$userConfig.XXXXXX")
        "$jq" --slurpfile m "$managed" --arg home "$HOME" \
          "$prelude"' .permissions = $want | .autoAcceptWebSearch = true' "$userConfig" > "$tmp"
        if ${pkgs.diffutils}/bin/cmp -s "$tmp" "$userConfig"; then
          rm -f "$tmp"
        else
          mv "$tmp" "$userConfig"
        fi
      fi
    '';
  };
}
