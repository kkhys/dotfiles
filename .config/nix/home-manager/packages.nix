{
  pkgs,
  lib,
  hostSpec,
  inputs,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      # Git Tools
      ghq

      # Development Tools
      rustup
      # Python is reached through uv (`uv run`, `uvx`), which manages its own
      # interpreters, so no standalone python3 or pipx.
      uv
      shellcheck

      # Editor
      vim

      # Terminal Tools
      bat
      eza
      # Installed here rather than via sheldon so its completions sit on fpath
      # (through NIX_PROFILES) before compinit runs; sheldon sources plugins
      # after compinit, where zsh-completions never registered anything.
      zsh-completions

      # Data Processing
      jq
    ]
    ++ [
      # Agent-oriented HTTP client; not in nixpkgs, so it comes from its own flake
      inputs.ax.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals hostSpec.isWork [
      # Work-only Tools
      google-cloud-sdk
      colima
    ];
}
