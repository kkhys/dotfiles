{ pkgs, hostSpec, ... }:

{
  programs.gpg = {
    enable = true;
  };

  home.packages = [ pkgs.pinentry_mac ];

  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program /etc/profiles/per-user/${hostSpec.username}/bin/pinentry-mac
  '';
}
