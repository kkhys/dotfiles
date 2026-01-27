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

  # Home directory files
  homeFiles = [
    ".claude/CLAUDE.md"
    ".claude/settings.json"
  ];
in
{
  xdg.configFile = lib.genAttrs configFiles (file: {
    source = mkLink ".config/${file}";
  });

  home.file = lib.genAttrs homeFiles (file: {
    source = mkLink file;
  });
}
