{ config, lib, ... }:

{
  homebrew = lib.mkIf config.hostSpec.isWork {
    brews = [
      "docker"
      "docker-compose"
      "docker-buildx"
      "datadog-labs/pack/pup"
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
