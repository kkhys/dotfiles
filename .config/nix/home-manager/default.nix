{ lib, hostSpec, ... }:

{
  imports = [
    ./dotfiles.nix
    ./packages.nix
    ./programs/bun.nix
    ./programs/gh.nix
    ./programs/ghostty.nix
    ./programs/git.nix
    ./programs/gpg.nix
    ./programs/mise.nix
    ./programs/sheldon.nix
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/zsh.nix
  ];

  home.username = hostSpec.username;
  home.homeDirectory = lib.mkForce "/Users/${hostSpec.username}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
