{ pkgs, ... }:

{
  imports = [
    ./homebrew.nix
    ./homebrew-work.nix
    ./homebrew-personal.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
}
