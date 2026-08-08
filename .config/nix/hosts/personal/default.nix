{ ... }:

{
  imports = [ ./homebrew.nix ];

  hostSpec = {
    hostName = "personal";
    username = "kkhys";
    isWork = false;
  };
}
