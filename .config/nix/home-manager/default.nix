{ lib, hostSpec, ... }:

{
  imports = [
    ./dotfiles.nix
    ./git.nix
    ./packages.nix
    ./zsh.nix
  ];

  home.username = hostSpec.username;
  home.homeDirectory = lib.mkForce "/Users/${hostSpec.username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
