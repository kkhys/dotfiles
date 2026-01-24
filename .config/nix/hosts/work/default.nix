{ config, pkgs, ... }:

{
  hostSpec = {
    hostName = "work";
    username = "keisuke.hayashi";
    isWork = true;
  };

  home.packages = with pkgs; [
  ];

  programs.zsh.shellAliases = {
  };

  home.sessionVariables = {
  };
}
