{ config, lib, ... }:

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
    "settings.json"
  ];

  # Gemini config files (stored in .config/gemini/, linked to ~/.gemini/)
  geminiFiles = [
    "settings.json"
  ];

  # Codex config files (stored in .config/codex/, linked to ~/.codex/)
  codexFiles = [
    "config.toml"
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
  }) codexFiles) // {
    # SSH public key
    ".ssh/id_ed25519_github.pub".source = mkLink ".config/nix/secrets/id_ed25519_github.pub";
  };
}
