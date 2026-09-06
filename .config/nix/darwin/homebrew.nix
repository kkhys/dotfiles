{ config, inputs, ... }:

{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  homebrew = {
    enable = true;
    onActivation = {
      # All taps are pinned as flake inputs (read-only nix store), so `brew update`
      # cannot fetch them and fails on the read-only tap .git. Updates flow through
      # `nix flake update` instead, so auto-update is disabled here.
      autoUpdate = false;
      upgrade = true;
      cleanup = "uninstall";
    };
    taps = [
      "homebrew/core"
      "homebrew/cask"
      "datadog-labs/pack"
    ];
  };

  nix-homebrew = {
    enable = true;
    user = config.hostSpec.username;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "datadog-labs/homebrew-pack" = inputs.homebrew-datadog;
    };
    mutableTaps = true;
  };
}
