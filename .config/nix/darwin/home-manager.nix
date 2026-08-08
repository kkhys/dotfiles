{ config, inputs, ... }:

{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      hostSpec = config.hostSpec;
    };
    users.${config.hostSpec.username} = import ../home-manager;
  };
}
