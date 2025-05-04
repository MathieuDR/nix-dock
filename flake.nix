{
  description = "NixOS Configuration for server";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nur.url = "github:nix-community/NUR";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yvim = {
      url = "github:mathieudr/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nur,
    home-manager,
    nix-index-database,
    disko,
    flake-utils,
    agenix,
    ...
  }:
    with inputs; let
      PII = builtins.fromJSON (builtins.readFile "${self}/secrets/PII.json");

      nixpkgsWithOverlays = rec {
        config = {
          permittedInsecurePackages = [
          ];
        };
        overlays = [
          nur.overlays.default
          (_final: prev: {
            # this allows us to reference pkgs.unstable
            unstable = import nixpkgs-unstable {
              inherit (prev) system;
              inherit config;
            };
          })
        ];
      };

      configurationDefaults = args: {
        nixpkgs = nixpkgsWithOverlays;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = args;
      };

      argDefaults = {
        inherit PII inputs self nix-index-database;
        channels = {
          inherit nixpkgs nixpkgs-unstable;
        };
      };

      mkNixosConfiguration = {
        system ? "x86_64-linux",
        hostname,
        username,
        args ? {},
        modules,
      }: let
        specialArgs = argDefaults // {inherit hostname username;} // args;
      in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.nixosModules.home-manager
              agenix.nixosModules.default
            ]
            ++ modules;
        };
    in
      {
        formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

        nixosConfigurations.nixos = mkNixosConfiguration {
          hostname = PII.host or "nixserver";
          username = PII.user or "nix";
          modules = [
            disko.nixosModules.disko
            ./hetzner.nix
            ./configuration.nix
          ];
        };
      }
      // flake-utils.lib.eachDefaultSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          config = nixpkgsWithOverlays.config;
          overlays = nixpkgsWithOverlays.overlays;
        };
      in {
        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            backblaze-b2
            just
            agenix.packages.${system}.default
            git-agecrypt
            age
          ];
        };
      });
}
