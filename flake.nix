{
  description = "Minimal Hyprland-first NixOS installer payload for Huawei MACH-W29";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nvchad-starter = {
      url = "github:NvChad/starter";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, zig-overlay, nvchad-starter, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.mach-w29 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit self nvchad-starter;
        };
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ zig-overlay.overlays.default ];
          })
          ./configuration.nix
        ];
      };
    };
}
