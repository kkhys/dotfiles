{ config, pkgs, ... }:

{
  hostSpec = {
    hostName = "mini";
    username = "kkhys";
    isWork = false;
  };

  home.packages = with pkgs; [
  ];
}
