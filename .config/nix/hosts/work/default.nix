{ ... }:

{
  imports = [ ./homebrew.nix ];

  hostSpec = {
    hostName = "work";
    username = "keisuke.hayashi";
    isWork = true;
  };
}
