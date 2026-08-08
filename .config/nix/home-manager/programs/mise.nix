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
        "npm:@google/gemini-cli" = "latest";
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
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="${config.home.profileDirectory}/bin:$PATH"
    ${pkgs.mise}/bin/mise install
    ${pkgs.mise}/bin/mise upgrade
  '';
}
