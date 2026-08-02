{ pkgs, lib, hostSpec, ax, ... }:

{
  home.packages = with pkgs; [
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

    # Data Processing
    jq

    # JavaScript/TypeScript Runtime
    deno
  ] ++ [
    # Agent-oriented HTTP client; not in nixpkgs, so it comes from its own flake
    ax.packages.${pkgs.system}.default
  ] ++ lib.optionals hostSpec.isWork [
    # Work-only Tools
    colima
  ];
}
