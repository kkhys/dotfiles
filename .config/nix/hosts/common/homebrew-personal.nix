{ config, lib, ... }:

{
  homebrew = lib.mkIf (!config.hostSpec.isWork) {
    brews = [
      "docker"
    ];

    casks = [
      "adobe-creative-cloud"
      "aqua-voice"
    ];
  };
}
