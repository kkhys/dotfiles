{
  config,
  lib,
  pkgs,
  hostSpec,
  ...
}:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        node = "latest";
        # pnpm 12's npm package swaps in a native binary from an install script
        # that mise's npm backend skips, so the registry (aqua) entry is used.
        pnpm = "latest";
        "npm:@openai/codex" = "latest";
      }
      // lib.optionalAttrs hostSpec.isWork {
        "npm:yarn" = "latest";
      };

      settings = {
        idiomatic_version_file_enable_tools = [ "node" ];
      };
    };
  };

  # `mise install` never moves a "latest" pin, hence the upgrade; prune drops
  # superseded versions, tools removed from this config and `mise use` leftovers.
  # After linkGeneration, not writeBoundary: writeBoundary runs before the
  # dotfile links, so mise would read the previous generation's config.toml.
  # Registry errors only warn, aborting would leave the system profile switched
  # but never activated.
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    PATH="${config.home.profileDirectory}/bin:$PATH"
    if ! (
      ${pkgs.mise}/bin/mise install \
        && ${pkgs.mise}/bin/mise upgrade \
        && ${pkgs.mise}/bin/mise prune --yes
    ); then
      echo "warning: mise tool refresh incomplete (offline or registry error?)" >&2
    fi
  '';
}
