{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        serverAliveInterval = 60;
        serverAliveCountMax = 5;
      };

      "github.com github" = {
        hostname = "github.com";
        user = "git";
        addKeysToAgent = "yes";
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
        extraOptions = {
          UseKeychain = "yes";
        };
      };
    };
  };
}
