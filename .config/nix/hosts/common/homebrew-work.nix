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
      "blackhole-2ch"
      "microsoft-edge"
      "openvpn-connect"
      # "ovice"
      "slack"
      # "zoom"
    ];
  };
}
