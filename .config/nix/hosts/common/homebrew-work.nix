{ config, lib, ... }:

{
  homebrew = lib.mkIf config.hostSpec.isWork {
    brews = [
      "docker"
      "docker-compose"
      "docker-buildx"
    ];

    casks = [
      "microsoft-edge"
      "openvpn-connect"
      # "ovice"
      "slack"
      # "zoom"
    ];
  };
}
