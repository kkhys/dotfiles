{
  config,
  lib,
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

  claudeSettingsFile = if hostSpec.isWork then "settings-work.json" else "settings.json";
  codexConfigFile = if hostSpec.isWork then "config-work.toml" else "config.toml";
in
{
  xdg.configFile = lib.genAttrs configFiles (file: {
    source = mkLink ".config/${file}";
  });

  home.file = {
    # One instruction file for every agent; each tool only reads its own name.
    ".claude/CLAUDE.md".source = mkLink ".config/agents/AGENTS.md";
    ".codex/AGENTS.md".source = mkLink ".config/agents/AGENTS.md";
    ".pi/agent/AGENTS.md".source = mkLink ".config/agents/AGENTS.md";
    # Codex writes through this link (/model, trust, plugin installs), so a
    # change made in Codex lands in the repo as a diff to commit or revert. One
    # file per host: both hosts write state and a shared file conflicted on pull.
    ".codex/config.toml".source = mkLink ".config/codex/${codexConfigFile}";
    ".claude/statusline-command.sh".source = mkLink ".config/claude/statusline-command.sh";
    ".claude/settings.json".source = mkLink ".config/claude/${claudeSettingsFile}";
    # pi writes through this link too (/model Ctrl+S, /settings), like Codex.
    ".pi/agent/settings.json".source = mkLink ".config/pi/settings.json";
    ".pi/agent/permissions.json".source = mkLink ".config/pi/permissions.json";
    ".pi/agent/presets.json".source = mkLink ".config/pi/presets.json";
    ".pi/agent/extensions".source = mkLink ".config/pi/extensions";
    ".pi/agent/agents".source = mkLink ".config/pi/agents";
    ".pi/agent/prompts".source = mkLink ".config/pi/prompts";
    # Hex writes through this link (Settings, `hex settings set`), like Codex.
    "Library/Application Support/hex/settings.json".source = mkLink ".config/hex/settings.json";
    ".ssh/id_ed25519_github.pub".source = mkLink ".config/nix/secrets/id_ed25519_github.pub";
  };
}
