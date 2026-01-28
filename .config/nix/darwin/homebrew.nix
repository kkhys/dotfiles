{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
    };
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
    ];
  };
}
