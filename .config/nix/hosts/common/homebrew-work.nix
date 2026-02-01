{ config, lib, ... }:

{
  homebrew = lib.mkIf config.hostSpec.isWork {
    brews = [
      "colima"
    ];

    casks = [
      "slack"
    ];
  };
}
