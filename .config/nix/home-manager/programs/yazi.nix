{ ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = true;
      };
      opener = {
        edit = [
          { run = ''vim "$@"''; block = true; }
        ];
      };
    };
  };
}
