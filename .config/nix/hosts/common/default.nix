{ pkgs, ... }:

{
  imports = [ ./homebrew.nix ];

  environment.systemPackages = with pkgs; [
    git
    vim
  ];
}
