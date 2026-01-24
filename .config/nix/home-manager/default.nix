{ lib, pkgs, config, ... }:

{
  imports = [
    ./dotfiles.nix
    ./packages.nix
    ./zsh.nix
  ];

  home.username = config.hostSpec.username;
  home.homeDirectory = lib.mkForce "/Users/${config.hostSpec.username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
