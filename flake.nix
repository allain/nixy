{
  description = "Portable Hyprland-first NixOS payload (multi-host)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nvchad-starter = {
      url = "github:NvChad/starter";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zig-overlay, nvchad-starter, home-manager, ... }:
    let
      system = "x86_64-linux";
      identity = import ./identity.nix;

      mkHost = machineModule: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit self nvchad-starter;
        };
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ zig-overlay.overlays.default ];
          })
          ./configuration.nix
          machineModule
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${identity.userName} = import ./home.nix { inherit nvchad-starter; };
          }
        ];
      };
    in
    {
      nixosConfigurations.mach-w29 = mkHost ./machine-mach-w29.nix;
      nixosConfigurations.nuc8i7hvk = mkHost ./machine-nuc8i7hvk.nix;
    };
}
