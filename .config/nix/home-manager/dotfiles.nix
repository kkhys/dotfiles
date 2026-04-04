{ config, lib, hostSpec, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/projects/github.com/kkhys/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";

  # XDG config files (under .config/)
  configFiles = [
    "karabiner/karabiner.json"
    "zed/settings.json"
    "zellij/config.kdl"
  ];

  # Claude config files (stored in .config/claude/, linked to ~/.claude/)
  claudeFiles = [
    "CLAUDE.md"
    "RTK.md"
    "hooks/rtk-rewrite.sh"
    "statusline-command.sh"
  ];

  claudeSettingsFile = if hostSpec.isWork then "settings-work.json" else "settings.json";

  # Gemini config files (stored in .config/gemini/, linked to ~/.gemini/)
  geminiFiles = [
    "settings.json"
  ];

  # Copilot config files (stored in .config/copilot/, linked to ~/.copilot/)
  copilotFiles = [
    "copilot-instructions.md"
  ];

  # Codex config files (stored in .config/codex/, linked to ~/.codex/)
  # Note: config.toml is excluded from symlinks because Codex writes runtime
  # state (project trust levels) to it. It is bootstrapped via activation script.
  codexFiles = [
    "AGENTS.md"
  ];
in
{
  xdg.configFile = lib.genAttrs configFiles (file: {
    source = mkLink ".config/${file}";
  });

  home.file = builtins.listToAttrs (map (file: {
    name = ".claude/${file}";
    value = { source = mkLink ".config/claude/${file}"; };
  }) claudeFiles) // builtins.listToAttrs (map (file: {
    name = ".gemini/${file}";
    value = { source = mkLink ".config/gemini/${file}"; };
  }) geminiFiles) // builtins.listToAttrs (map (file: {
    name = ".codex/${file}";
    value = { source = mkLink ".config/codex/${file}"; };
  }) codexFiles) // builtins.listToAttrs (map (file: {
    name = ".copilot/${file}";
    value = { source = mkLink ".config/copilot/${file}"; };
  }) copilotFiles) // {
    # Claude settings (host-specific: personal uses settings.json, work uses settings-work.json)
    ".claude/settings.json".source = mkLink ".config/claude/${claudeSettingsFile}";
    # SSH public key
    ".ssh/id_ed25519_github.pub".source = mkLink ".config/nix/secrets/id_ed25519_github.pub";
  };

  home.activation = {
    # Bootstrap Codex config.toml if it doesn't exist yet.
    # Codex writes runtime state (project trust) to this file, so it must not be a symlink.
    codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -f "$HOME/.codex/config.toml" ]; then
        mkdir -p "$HOME/.codex"
        cp "${dotfilesPath}/.config/codex/config.toml" "$HOME/.codex/config.toml"
      fi
    '';
  } // lib.optionalAttrs hostSpec.isWork {
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
