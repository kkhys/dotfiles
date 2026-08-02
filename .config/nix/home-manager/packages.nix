{ pkgs, lib, hostSpec, ... }:

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
  ] ++ lib.optionals hostSpec.isWork [
    # Work-only Tools
    colima
  ];
}
