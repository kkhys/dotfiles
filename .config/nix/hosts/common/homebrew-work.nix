{ config, lib, ... }:

{
  homebrew = lib.mkIf config.hostSpec.isWork {
    brews = [
      "colima"
    ];

    casks = [
      "microsoft-edge"
      "openvpn-connect"
      # "ovice"
      "slack"
    ];
  };
}
