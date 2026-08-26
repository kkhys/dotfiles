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
      gibo
      lefthook

      # Development Tools
      rustup
      python3
      uv
      pipx
      shellcheck

      # Cloud Tools
      google-cloud-sdk

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

      # JavaScript/TypeScript Runtime
      deno
    ]
    ++ [
      # Agent-oriented HTTP client; not in nixpkgs, so it comes from its own flake
      inputs.ax.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ lib.optionals hostSpec.isWork [
      # Work-only Tools
      colima
    ];
}
