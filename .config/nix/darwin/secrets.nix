{ config, lib, ... }:

let
  secretsPath = ../secrets;
  username = config.hostSpec.username;
  # Check if encrypted files exist
  sshKeyExists = builtins.pathExists "${secretsPath}/ssh-key-github.age";
  gpgKeyExists = builtins.pathExists "${secretsPath}/gpg-key.age";
  npmTokenExists = builtins.pathExists "${secretsPath}/npm-token.age";
  githubTokenExists = builtins.pathExists "${secretsPath}/github-token.age";
  qaseApiTokenExists = builtins.pathExists "${secretsPath}/qase-api-token.age";
in
{
  # Path to the age private key used for decryption
  age.identityPaths = [
    "/Users/${username}/.config/age/keys.txt"
  ];

  # Secrets to decrypt (only if encrypted files exist)
  age.secrets = lib.mkMerge [
    (lib.mkIf sshKeyExists {
      ssh-key-github = {
        file = "${secretsPath}/ssh-key-github.age";
        path = "/Users/${username}/.ssh/id_ed25519_github";
        owner = username;
        mode = "600";
      };
    })
    (lib.mkIf gpgKeyExists {
      gpg-key = {
        file = "${secretsPath}/gpg-key.age";
        path = "/Users/${username}/.gnupg/agenix-key.asc";
        owner = username;
        mode = "600";
      };
    })
    (lib.mkIf (npmTokenExists && config.hostSpec.isWork) {
      npm-token = {
        file = "${secretsPath}/npm-token.age";
        path = "/Users/${username}/.config/secrets/npm-token";
        owner = username;
        mode = "600";
      };
    })
    (lib.mkIf githubTokenExists {
      github-token = {
        file = "${secretsPath}/github-token.age";
        path = "/Users/${username}/.config/secrets/github-token";
        owner = username;
        mode = "600";
      };
    })
    (lib.mkIf (qaseApiTokenExists && config.hostSpec.isWork) {
      qase-api-token = {
        file = "${secretsPath}/qase-api-token.age";
        path = "/Users/${username}/.config/secrets/qase-api-token";
        owner = username;
        mode = "600";
      };
    })
  ];
}
