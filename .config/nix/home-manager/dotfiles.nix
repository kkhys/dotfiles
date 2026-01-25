{ config, pkgs, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/projects/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in
{
  # Files under ~/.config/
  xdg.configFile = {
    "zed/settings.json".source = mkLink ".config/zed/settings.json";
    "git".source = mkLink ".config/git";
    "karabiner".source = mkLink ".config/karabiner";
    "mise".source = mkLink ".config/mise";
    "ghostty".source = mkLink ".config/ghostty";
  };

  # Files under ~/
  home.file = {
    # Note: .zshrc is managed by programs.zsh, not symlinked
    ".gitconfig".source = mkLink ".gitconfig";
  };
}
