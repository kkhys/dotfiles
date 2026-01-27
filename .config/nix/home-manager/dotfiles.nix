{ config, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/projects/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";

  mkConfigFiles = files:
    lib.genAttrs files (file: { source = mkLink ".config/${file}"; });

  mkHomeFiles = files: lib.genAttrs files (file: { source = mkLink file; });
in
{
  xdg.configFile = mkConfigFiles [
    "karabiner"
    "gh"
    "zellij"
  ] // {
    "zed/settings.json".source = mkLink ".config/zed/settings.json";
  };

  home.file = mkHomeFiles [
    ".claude/CLAUDE.md"
    ".claude/settings.json"
  ];
}
