{ config, lib, ... }:

{
  homebrew = lib.mkIf config.hostSpec.isWork {
    casks = [
      "microsoft-edge"
      "openvpn-connect"
      # "ovice"
      "slack"
      # "zoom"
    ];
  };
}
