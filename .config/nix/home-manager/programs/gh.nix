{ ... }:

{
  programs.gh = {
    enable = true;

    settings = {
      git_protocol = "https";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      pager = "";
      color_labels = "disabled";
      accessible_colors = "disabled";
      accessible_prompter = "disabled";
      spinner = "enabled";

      aliases = {
        co = "pr checkout";
        il = "issue list";
        iv = "issue view --web";
        op = "repo view --web";
        pc = "pr create --web";
        pl = "pr list";
        pv = "pr view --web";
        rl = "run list";
        rw = "run watch";
      };
    };

    gitCredentialHelper = {
      enable = false;
    };
  };
}
