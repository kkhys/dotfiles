{ config, pkgs, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/projects/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/${path}";
in
{
  # Files under ~/.config/
  xdg.configFile = {
    # Editor and tools
    # "zed".source = mkLink ".config/zed";
    "git".source = mkLink ".config/git";
    # "github-copilot".source = mkLink ".config/github-copilot";
    # "karabiner".source = mkLink ".config/karabiner";
  };

  # Files under ~/
  home.file = {
    # ".gitconfig".source = mkLink ".gitconfig";
    # Note: .zshrc is managed by programs.zsh, not symlinked
  };
}
