{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # Git Tools
    ghq

    # Development Tools
    # Agent tooling shells out to a bare `python3`: the security-guidance
    # plugin hooks and the trend digest skill. macOS only offers 3.9.6 behind
    # an xcrun shim, which is below the 3.10 claude_agent_sdk requires and
    # fails outright inside a nix devShell, where DEVELOPER_DIR points at an
    # SDK that carries no interpreter.
    python3
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
  ];
}
