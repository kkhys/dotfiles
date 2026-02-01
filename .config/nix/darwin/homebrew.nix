{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    taps = [
      "homebrew/core"
      "homebrew/cask"
      "protonpass/tap"
    ];
  };
}
