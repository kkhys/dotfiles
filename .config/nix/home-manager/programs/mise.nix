{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        node = "latest";
        "npm:pnpm" = "latest";
        "npm:yarn" = "latest";
        "npm:@openai/codex" = "latest";
        "npm:vercel" = "latest";
      };

      settings = {
        idiomatic_version_file_enable_tools = [ "node" ];
      };
    };
  };

  # `mise install` only installs missing tools, so tools pinned to "latest"
  # stay frozen at whatever version was current on first install. Upgrade
  # afterwards so "latest" actually tracks latest.
  #
  # After linkGeneration, not writeBoundary: the DAG otherwise orders this
  # step before the dotfile links, so mise would read the previous
  # generation's config.toml and act on tools this rebuild just dropped.
  # Registry errors only warn, like the other network-bound steps; aborting
  # here would leave the system profile switched but never activated.
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    PATH="${config.home.profileDirectory}/bin:$PATH"
    if ! (
      ${pkgs.mise}/bin/mise install \
        && ${pkgs.mise}/bin/mise upgrade
    ); then
      echo "warning: mise tool refresh incomplete (offline or registry error?)" >&2
    fi
  '';
}
