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
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };
    # nix-homebrew still pins brew 7.0.4; homebrew-core/cask are unpinned, so
    # brew must track upstream closely enough to parse their current DSL
    # (`resource "...", :test` needs 7.0.9, `zap :not_required` needs 7.0.11).
    # Drop once upstream bumps brew-src past 7.0.11.
    # https://github.com/zhaofengli/nix-homebrew/issues/192
    brew-src = {
      url = "github:Homebrew/brew/7.0.11";
      flake = false;
    };
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
    homebrew-orca = {
      url = "github:stablyai/homebrew-orca";
      flake = false;
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Agent skills, linked into place by home-manager/skills.nix.
    skills-gh-stack = {
      url = "github:github/gh-stack";
      flake = false;
    };
    skills-gh-actions-lock = {
      url = "github:github/gh-actions-lock";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, darwin, ... }@inputs:
    let
      system = "aarch64-darwin";

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
