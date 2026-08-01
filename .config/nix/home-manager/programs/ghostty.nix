{ config, lib, ... }:

{
  programs.ghostty = {
    enable = true;

    # Set to null because Ghostty is installed via Homebrew on macOS
    package = null;

    settings = {
      theme = "Catppuccin Mocha";

      # Attach every surface to herdr instead of a bare shell.
      # An absolute store path is required: the Ghostty app is launched by
      # launchd, whose PATH does not include the Home Manager profile.
      command = lib.getExe config.programs.herdr.package;

      # `detect` would find herdr (not a shell) and skip injection, so force the
      # zsh scheme. Pane shells spawned by herdr then inherit the integration.
      shell-integration = "zsh";

      macos-option-as-alt = true;

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
