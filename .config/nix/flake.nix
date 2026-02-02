{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      darwin,
      home-manager,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      agenix,
      ...
    }:
    let
      system = "aarch64-darwin";

      commonModules = [
        ./modules/host-spec.nix
        ./hosts/common
        ./darwin
        agenix.darwinModules.default
        # Add agenix CLI to system packages
        { environment.systemPackages = [ agenix.packages.${system}.default ]; }
        home-manager.darwinModules.home-manager
        (
          { config, ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                hostSpec = config.hostSpec;
              };
              users.${config.hostSpec.username} = import ./home-manager;
            };
          }
        )
        nix-homebrew.darwinModules.nix-homebrew
        (
          { config, ... }:
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = config.hostSpec.username;
              autoMigrate = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };
              mutableTaps = true;
            };
          }
        )
      ];
    in
    {
      darwinConfigurations = {
        personal = darwin.lib.darwinSystem {
          inherit system;
          modules = [ ./hosts/personal ] ++ commonModules;
        };

        work = darwin.lib.darwinSystem {
          inherit system;
          modules = [ ./hosts/work ] ++ commonModules;
        };
      };
    };
}
