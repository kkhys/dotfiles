{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Git Tools
    ghq
    gibo
    lefthook

    # Development Tools
    uv

    # Editor
    vim

    # Terminal Tools
    bat
    eza
    zellij

    # Data Processing
    jq

    # JavaScript/TypeScript Runtime
    deno
  ];
}
