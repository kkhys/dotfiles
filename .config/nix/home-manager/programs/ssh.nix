{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ServerAliveInterval = 60;
        ServerAliveCountMax = 5;
      };

      "github.com github" = {
        HostName = "github.com";
        User = "git";
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/id_ed25519_github";
        IdentitiesOnly = true;
        UseKeychain = "yes";
      };
    };
  };
}
