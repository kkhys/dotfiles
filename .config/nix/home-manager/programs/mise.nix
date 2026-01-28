{ ... }:

{
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        node = "latest";
        pnpm = "latest";
        "npm:@google/gemini-cli" = "latest";
        "npm:@openai/codex" = "latest";
      };

      settings = {
        idiomatic_version_file_enable_tools = [ "node" ];
      };
    };
  };
}
