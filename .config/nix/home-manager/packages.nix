{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Git Tools
    git
    gh
    gibo
    lefthook

    # Security
    gnupg
    pinentry_mac

    # Development Tools
    uv

    # Editor
    vim

    # Terminal Tools
    zellij

    # Data Processing
    jq

    # JavaScript/TypeScript Runtime
    deno
    bun
    
    mise
  ];
}
