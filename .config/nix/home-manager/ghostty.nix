{ ... }:

{
  programs.ghostty = {
    enable = true;

    # Set to null because Ghostty is installed via Homebrew on macOS
    package = null;

    settings = {
      theme = "Catppuccin Mocha";
    };
  };
}
