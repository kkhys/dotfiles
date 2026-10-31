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

  # XDG config under .config/. Karabiner is linked as a whole directory: its
  # documentation warns that a symlinked karabiner.json is not watched for
  # changes, while a symlinked ~/.config/karabiner is supported. Karabiner then
  # writes assets/ and automatic_backups/ into this repo; .gitignore covers the
  # backups.
  configFiles = [
    "karabiner"
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
    # ~/.config/karabiner used to be a real directory holding a per-file link
    # to karabiner.json. Home Manager would move it aside as karabiner.backup,
    # so dissolve it first: drop the old link, carry Karabiner's own state into
    # the repo directory when it holds any files, and stop on anything else.
    karabinerDirMigration = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      karabinerDir="$HOME/.config/karabiner"
      karabinerRelinked=
      if [ -d "$karabinerDir" ] && [ ! -L "$karabinerDir" ]; then
        if [ -L "$karabinerDir/karabiner.json" ]; then
          run rm "$karabinerDir/karabiner.json"
        fi
        for state in assets automatic_backups; do
          [ -d "$karabinerDir/$state" ] || continue
          if [ -z "$(find "$karabinerDir/$state" -type f)" ]; then
            run rm -r "$karabinerDir/$state"
          elif [ -e "${dotfilesPath}/.config/karabiner/$state" ]; then
            echo "error: both $karabinerDir/$state and ${dotfilesPath}/.config/karabiner/$state exist; merge them by hand and rerun" >&2
            exit 1
          else
            run mv "$karabinerDir/$state" "${dotfilesPath}/.config/karabiner/"
          fi
        done
        if ! run rmdir "$karabinerDir"; then
          echo "error: unexpected entries left in $karabinerDir; move them aside and rerun" >&2
          exit 1
        fi
        karabinerRelinked=1
      fi
    '';

    # Karabiner-Console-User-Server keeps watching the path it started with, so
    # restart it once after the directory was relinked (the documented step)
    # rather than on every switch. Reads karabinerRelinked from the entry
    # above; the activation entries run in one shell.
    karabinerReload = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -n "''${karabinerRelinked:-}" ]; then
        run /bin/launchctl kickstart -k "gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server" \
          || echo "warning: restart Karabiner-Console-User-Server by hand so it watches ~/.config/karabiner" >&2
      fi
    '';

    # This file used to copy a Claude permission mirror to
    # ~/.codex/rules/managed.rules. The mirror is gone, and a stale copy would
    # keep enforcing the old tiers, so remove it.
    codexRulesCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -f "$HOME/.codex/rules/managed.rules"
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
  };
}
