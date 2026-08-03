{ pkgs, ... }:

let
  tomlFormat = pkgs.formats.toml { };
in
{
  # hunk exports a home-manager module from its own flake, but home-manager
  # itself carries none. The module only writes this file, sets the git pager,
  # and links the agent skill, so it is not worth a flake input on top of the
  # `hunk` already in nixpkgs.
  home.packages = [ pkgs.hunk ];

  # Keys are limited to what the pinned 0.17.x understands; `tab_width` and
  # `[keybindings]` only landed in 0.18
  xdg.configFile."hunk/config.toml".source = tomlFormat.generate "hunk-config.toml" {
    # Matches the Ghostty theme
    theme = "catppuccin-mocha";

    # Terminal width picks split vs stack
    mode = "auto";

    line_numbers = true;

    # Agent annotations are the reason hunk is here rather than a plain diff
    # pager, so they start visible instead of behind `a`
    agent_notes = true;
  };
}
