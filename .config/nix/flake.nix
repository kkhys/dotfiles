{
  description = "Darwin configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";

      commonModules = [
        ./modules/hostSpec.nix
        ./home-manager
        ./hosts/common
      ];

      mkHomeConfiguration = hostModule: home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ hostModule ] ++ commonModules;
      };
    in
    {
      homeConfigurations = {
        kkhys = mkHomeConfiguration ./hosts/kkhys;
        work = mkHomeConfiguration ./hosts/work;
      };
    };
}
