{ lib, pkgs, ... }:

{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  # The module's launchd agent runs `gpg-agent --supervised`, which only
  # understands systemd socket passing (LISTEN_FDS, fd 3). launchd hands
  # sockets over through its own API instead, so the agent dies with exit 2
  # and KeepAlive respawns it every 10s. gpg autostarts its own agent on the
  # standard socket anyway; only the generated gpg-agent.conf and GPG_TTY
  # export are wanted from the module.
  launchd.agents.gpg-agent.enable = lib.mkForce false;
}
