{ ... }:

{
  programs.starship = {
    enable = true;

    settings = {
      add_newline = true;
      package.disabled = true;
      aws.disabled = true;
    };
  };
}
