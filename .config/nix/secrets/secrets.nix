let
  kkhys = "age1ex5l48vz4atvvv9zaz5nmlhcu4x6y8387ss4q0dwdujvs8l469qqwxngpw";
  allKeys = [ kkhys ];
in
{
  "ssh-key-github.age".publicKeys = allKeys;
  # Plaintext is `gpg --export-secret-keys --armor <key-id>`.
  "gpg-key.age".publicKeys = allKeys;
  "npm-token.age".publicKeys = allKeys;
  "github-token.age".publicKeys = allKeys;
  "qase-api-token.age".publicKeys = allKeys;
}
