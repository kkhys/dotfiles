{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  secretsPath = ../secrets;
  username = config.hostSpec.username;
  home = "/Users/${username}";

  # One entry per *.age file. `dest` is relative to $HOME and defaults to
  # .config/secrets/<name>; `workOnly` secrets decrypt only when
  # hostSpec.isWork. Env-var wiring lives in home-manager/programs/zsh.nix.
  secrets = {
    ssh-key-github.dest = ".ssh/id_ed25519_github";
    gpg-key.dest = ".gnupg/agenix-key.asc";
    github-token = { };
    npm-token.workOnly = true;
    qase-api-token.workOnly = true;
    sonarqube-token.workOnly = true;
  };

  wanted = lib.filterAttrs (
    name: secret:
    builtins.pathExists "${secretsPath}/${name}.age"
    && (config.hostSpec.isWork || !(secret.workOnly or false))
  ) secrets;
in
{
  imports = [ inputs.agenix.darwinModules.default ];

  environment.systemPackages = [ inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  age.identityPaths = [ "${home}/.config/age/keys.txt" ];

  age.secrets = lib.mapAttrs (name: secret: {
    file = "${secretsPath}/${name}.age";
    path = "${home}/${secret.dest or ".config/secrets/${name}"}";
    owner = username;
    mode = "600";
  }) wanted;
}
