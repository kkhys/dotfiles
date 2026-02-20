# agenix secrets configuration
# Usage: cd .config/nix && agenix -e secrets/ssh-key-github.age
let
  # User's age public key (dedicated age key)
  kkhys = "age1ex5l48vz4atvvv9zaz5nmlhcu4x6y8387ss4q0dwdujvs8l469qqwxngpw";

  # All keys that can decrypt secrets
  allKeys = [ kkhys ];
in
{
  # SSH private key for GitHub
  "ssh-key-github.age".publicKeys = allKeys;

  # GPG private key (exported with: gpg --export-secret-keys --armor KEY_ID)
  "gpg-key.age".publicKeys = allKeys;

  # NPM token for GitHub Packages
  "npm-token.age".publicKeys = allKeys;

  # GitHub personal access token
  "github-token.age".publicKeys = allKeys;

  # Qase API token
  "qase-api-token.age".publicKeys = allKeys;

  # SonarQube token
  "sonarqube-token.age".publicKeys = allKeys;
}
