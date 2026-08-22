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
    homebrew-datadog = {
      url = "github:datadog-labs/homebrew-pack";
      flake = false;
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ax = {
      url = "github:yusukebe/ax";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, darwin, ... }@inputs:
    let
      system = "aarch64-darwin";

      # Wiring of upstream modules (home-manager, nix-homebrew, agenix) lives
      # next to their configuration under ./darwin, reached through
      # `specialArgs.inputs`, so adding a host stays a one-liner here.
      mkHost =
        host:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./modules/host-spec.nix
            ./hosts/${host}
            ./hosts/common
            ./darwin
          ];
        };
    in
    {
      darwinConfigurations = {
        personal = mkHost "personal";
        work = mkHost "work";
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-tree;
    };
}
