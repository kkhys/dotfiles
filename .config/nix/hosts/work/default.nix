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
}
