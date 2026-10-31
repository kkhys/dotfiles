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

  # Karabiner is linked as a whole directory: a symlinked karabiner.json is not
  # watched for changes, a symlinked ~/.config/karabiner is. Karabiner then
  # writes assets/ and automatic_backups/ into this repo.
  configFiles = [
    "karabiner"
    "zed/settings.json"
  ];

  # Codex's config.toml is absent on purpose: Codex rewrites ~/.codex/config.toml
  # in place, so the managed settings ship through the system layer instead
  # (darwin/codex.nix).
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
      ".claude/settings.json".source = mkLink ".config/claude/${claudeSettingsFile}";
      ".ssh/id_ed25519_github.pub".source = mkLink ".config/nix/secrets/id_ed25519_github.pub";
    };

  home.activation = {
    # ~/.config/karabiner used to be a real directory holding a per-file link
    # to karabiner.json, which Home Manager would move aside as karabiner.backup.
    # Dissolve it first, carrying Karabiner's own state into the repo directory.
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
    # restart it once after the relink. karabinerRelinked comes from the entry
    # above; activation entries run in one shell.
    karabinerReload = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -n "''${karabinerRelinked:-}" ]; then
        run /bin/launchctl kickstart -k "gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server" \
          || echo "warning: restart Karabiner-Console-User-Server by hand so it watches ~/.config/karabiner" >&2
      fi
    '';

    # Leftover of a Claude permission mirror this file used to install; a stale
    # copy keeps enforcing the old tiers.
    codexRulesCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -f "$HOME/.codex/rules/managed.rules"
    '';

    # /etc/codex/config.toml is Codex's lowest-precedence layer, so a key left
    # in ~/.codex/config.toml silently shadows it.
    codexConfigShadowCheck = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      userConfig="$HOME/.codex/config.toml"
      systemConfig="/etc/codex/config.toml"
      if [ -f "$userConfig" ] && [ -f "$systemConfig" ]; then
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
