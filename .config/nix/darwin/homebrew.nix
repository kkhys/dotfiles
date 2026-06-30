{ ... }:

{
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
      "protonpass/tap"
      "entireio/tap"
      "datadog-labs/pack"
      "manaflow-ai/cmux"
      "rtk-ai/tap"
    ];
  };
}
