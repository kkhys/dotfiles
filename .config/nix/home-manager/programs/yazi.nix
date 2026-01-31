{ ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

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
