{ config, inputs, ... }:

{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  homebrew = {
    enable = true;
    onActivation = {
      # Taps are flake inputs in the read-only store, so `brew update` fails on
      # them; `nix flake update` moves them instead.
      autoUpdate = false;
      upgrade = true;
      cleanup = "uninstall";
    };
    # Keeps `brew bundle cleanup` from untapping the pinned taps; brew strips
    # the `homebrew-` repo prefix itself.
    taps = builtins.attrNames config.nix-homebrew.taps;
  };

  nix-homebrew = {
    enable = true;
    user = config.hostSpec.username;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "datadog-labs/homebrew-pack" = inputs.homebrew-datadog;
      "stablyai/homebrew-orca" = inputs.homebrew-orca;
    };
    mutableTaps = true;
  };
}
