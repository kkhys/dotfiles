{ config, lib, ... }:

{
  homebrew = lib.mkIf config.hostSpec.isWork {
    brews = [
    ];

    casks = [
    ];
  };
}
