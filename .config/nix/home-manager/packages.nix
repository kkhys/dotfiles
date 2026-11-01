{
  inputs,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    ghq

    # Coding agent harness; its config is linked from .config/pi by dotfiles.nix.
    inputs.pi.packages.${stdenv.hostPlatform.system}.default

    # Agent tooling shells out to a bare `python3`. macOS only offers 3.9.6
    # behind an xcrun shim, below the 3.10 claude_agent_sdk requires, and the
    # shim fails inside a nix devShell, where DEVELOPER_DIR carries no interpreter.
    python3
    uv
    shellcheck

    vim

    bat
    eza
    zsh-completions

    jq
  ];
}
