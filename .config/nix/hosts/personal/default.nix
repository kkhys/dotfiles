{ config, ... }:

{
  hostSpec = {
    hostName = "personal";
    username = "kkhys";
    isWork = false;
  };

  networking.hostName = config.hostSpec.hostName;
  system.primaryUser = config.hostSpec.username;

  users.users.${config.hostSpec.username} = {
    name = config.hostSpec.username;
    home = "/Users/${config.hostSpec.username}";
  };

  # environment.systemPackages = with pkgs; [
  # ];

  home-manager.users.${config.hostSpec.username} = {
    programs.zsh.shellAliases = {
      dr = "sudo darwin-rebuild switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal";
      drb = "sudo darwin-rebuild build --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal";
      drc = "sudo darwin-rebuild check --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#personal";
    };
  };
}
