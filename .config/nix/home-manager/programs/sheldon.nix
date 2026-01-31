{ ... }:

{
  programs.sheldon = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      shell = "zsh";

      plugins = {
        zsh-autosuggestions = {
          github = "zsh-users/zsh-autosuggestions";
        };

        zsh-completions = {
          github = "zsh-users/zsh-completions";
        };

        fast-syntax-highlighting = {
          github = "zdharma-continuum/fast-syntax-highlighting";
        };
      };
    };
  };
}
