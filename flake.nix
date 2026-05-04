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

      mkHost =
        { machineModule
        , monitorsConfig ? "monitor = ,preferred,auto,2\n"
        , workspacesConfig ? ''
            workspace = 1, default:true, persistent:true
            workspace = 2, persistent:true
            workspace = 3, persistent:true
            workspace = 4, persistent:true
            workspace = 5, persistent:true
            workspace = 6, persistent:true
            workspace = 7, persistent:true
            workspace = 8, persistent:true
            workspace = 9, persistent:true
            workspace = 10, persistent:true
          ''
        }:
        nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit self nvchad-starter monitorsConfig workspacesConfig;
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
            home-manager.users.${identity.userName} = import ./home.nix { inherit nvchad-starter monitorsConfig workspacesConfig; };
          }
        ];
      };
    in
    {
      nixosConfigurations.mach-w29 = mkHost {
        machineModule = ./machine-mach-w29.nix;
        monitorsConfig = ''
          # Samsung LF22T35 external: left side, native scale
          monitor = desc:Samsung Electric Company LF22T35, 1920x1080@60, 0x0, 1
          # Built-in laptop display: right of external, HiDPI
          monitor = eDP-1, 3000x2000@60, 1920x0, 2
          # Fallback for any other monitors
          monitor = , preferred, auto, 1
        '';
        workspacesConfig = ''
          # External monitor: stable left-side workspaces
          workspace = 1, monitor:desc:Samsung Electric Company LF22T35, default:true, persistent:true, defaultName:term
          workspace = 2, monitor:desc:Samsung Electric Company LF22T35, persistent:true, defaultName:web
          workspace = 3, monitor:desc:Samsung Electric Company LF22T35, persistent:true, defaultName:chat
          workspace = 4, monitor:desc:Samsung Electric Company LF22T35, persistent:true
          workspace = 5, monitor:desc:Samsung Electric Company LF22T35, persistent:true

          # Laptop panel: stable right-side workspaces
          workspace = 6, monitor:eDP-1, default:true, persistent:true, defaultName:notes
          workspace = 7, monitor:eDP-1, persistent:true
          workspace = 8, monitor:eDP-1, persistent:true
          workspace = 9, monitor:eDP-1, persistent:true
          workspace = 10, monitor:eDP-1, persistent:true
        '';
      };
      nixosConfigurations.nuc = mkHost {
        machineModule = ./machine-nuc8i7hvk.nix;
        monitorsConfig = "monitor = ,preferred,auto-up,1\n";
      };
    };
}
