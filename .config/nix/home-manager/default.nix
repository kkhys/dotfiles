{ lib, hostSpec, ... }:

{
  imports = [
    ./dotfiles.nix
    ./packages.nix
    ./programs/bun.nix
    ./programs/gh.nix
    ./programs/ghostty.nix
    ./programs/git.nix
    ./programs/mise.nix
    ./programs/zsh.nix
  ];

  home.username = hostSpec.username;
  home.homeDirectory = lib.mkForce "/Users/${hostSpec.username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
