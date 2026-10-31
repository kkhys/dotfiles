{ hostSpec, ... }:

{
  imports = [
    ./dotfiles.nix
    ./packages.nix
    ./skills.nix
    ./programs/bun.nix
    ./programs/direnv.nix
    ./programs/fzf.nix
    ./programs/gh.nix
    ./programs/git.nix
    ./programs/gpg.nix
    ./programs/mise.nix
    ./programs/sheldon.nix
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/zsh.nix
  ];

  home.username = hostSpec.username;
  home.homeDirectory = "/Users/${hostSpec.username}";
  home.stateVersion = "24.11";
}
