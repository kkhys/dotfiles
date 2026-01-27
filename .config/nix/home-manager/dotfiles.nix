{ config, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/projects/dotfiles";
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
in
{
  xdg.configFile = lib.genAttrs configFiles (file: {
    source = mkLink ".config/${file}";
  });

  home.file = builtins.listToAttrs (map (file: {
    name = ".claude/${file}";
    value = { source = mkLink ".config/claude/${file}"; };
  }) claudeFiles);
}
