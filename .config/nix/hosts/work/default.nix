{ config, ... }:

{
  hostSpec = {
    hostName = "work";
    username = "keisuke.hayashi";
    isWork = true;
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
      dr = "sudo darwin-rebuild switch --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#work";
      drb = "sudo darwin-rebuild build --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#work";
      drc = "sudo darwin-rebuild check --flake ~/projects/github.com/kkhys/dotfiles/.config/nix#work";
    };
  };
}
