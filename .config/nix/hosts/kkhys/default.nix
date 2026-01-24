{ config, pkgs, ... }:

{
  hostSpec = {
    hostName = "mini";
    username = "kkhys";
    isWork = false;
  };

  networking.hostName = config.hostSpec.hostName;
  system.primaryUser = config.hostSpec.username;

  users.users.${config.hostSpec.username} = {
    name = config.hostSpec.username;
    home = "/Users/${config.hostSpec.username}";
  };

  environment.systemPackages = with pkgs; [
  ];

  home-manager.users.${config.hostSpec.username} = {
    programs.zsh.shellAliases = {
      dr = "darwin-rebuild switch --flake ~/projects/dotfiles/.config/nix#kkhys";
      drb = "darwin-rebuild build --flake ~/projects/dotfiles/.config/nix#kkhys";
      drc = "darwin-rebuild check --flake ~/projects/dotfiles/.config/nix#kkhys";
    };
  };
}
