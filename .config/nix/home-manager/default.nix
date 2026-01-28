{ lib, hostSpec, ... }:

{
  imports = [
    ./bun.nix
    ./dotfiles.nix
    ./gh.nix
    ./ghostty.nix
    ./git.nix
    ./mise.nix
    ./packages.nix
    ./zsh.nix
  ];

  home.username = hostSpec.username;
  home.homeDirectory = lib.mkForce "/Users/${hostSpec.username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
