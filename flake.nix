{
  description = "Type B";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows        = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs";  # or the lock pulls a second nixpkgs
    };
  };

  outputs = { self, nixpkgs, disko, helium, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      # disko looks here before falling back to nixosConfigurations, and wants the whole module
      diskoConfigurations."1B" = import ./sys/nixos/modules/hardware/disk-1B.nix { };

      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./sys/nixos/iso.nix
          # Baked in so it matches the lock and partitions without network
          { environment.systemPackages = [ disko.packages.${system}.disko ]; }
        ];
      };

      packages.${system}.iso =
        self.nixosConfigurations.installer.config.system.build.isoImage;

      nixosConfigurations."1B" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          {
            nixpkgs.overlays = [
              (final: prev: {
                unstable = import inputs.nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;  # separate instance, so it needs its own
                };
                helium = helium.packages.${system}.default;
              })
            ];
          }
          ./sys/nixos/hosts/1B.nix
        ];
      };
    };
}
