{ ... }:

{
  programs.ghostty = {
    enable = true;

    # Set to null because Ghostty is installed via Homebrew on macOS
    package = null;

    settings = {
      theme = "Catppuccin Mocha";

      cursor-style = "block";
      cursor-style-blink = false;
      cursor-opacity = 0.7;

      mouse-hide-while-typing = true;

      window-padding-x = 5;
      window-padding-y = 5;
      window-padding-balance = true;

      background-opacity = 0.8;
      background-blur = true;

      shell-integration-features = "no-cursor";
    };
  };
}
