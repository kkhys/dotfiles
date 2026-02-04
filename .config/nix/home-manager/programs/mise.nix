{ config, lib, pkgs, ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        node = "latest";
        pnpm = "latest";
        "npm:yarn" = "latest";
        "npm:@fission-ai/openspec" = "latest";
        "npm:@google/gemini-cli" = "latest";
        "npm:@openai/codex" = "latest";
      };

      settings = {
        idiomatic_version_file_enable_tools = [ "node" ];
      };
    };
  };

  home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PATH="${config.home.profileDirectory}/bin:$PATH"
    ${pkgs.mise}/bin/mise install
  '';
}
