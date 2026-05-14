{
  description = "Portable Hyprland-first NixOS payload (multi-host)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pin for waybar < 0.15 (0.15.0 invisible on Hyprland — Waybar #4864).
    nixpkgs-waybar.url = "github:NixOS/nixpkgs/nixos-25.05";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";
    nvchad-starter = {
      url = "github:NvChad/starter";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    winpodx = {
      url = "github:kernalix7/winpodx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-waybar, zig-overlay, nvchad-starter, home-manager, winpodx, ... }:
    let
      system = "x86_64-linux";
      identity = import ./identity.nix;
      pkgsWaybar = import nixpkgs-waybar { inherit system; config.allowUnfree = true; };

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
          winpodxPkg = winpodx.packages.${system}.default.overrideAttrs (old: {
            doCheck = false;
            doInstallCheck = false;
            installCheckPhase = "true";
          });
        };
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [
              zig-overlay.overlays.default
              (final: prev: { waybar = pkgsWaybar.waybar; })
            ];
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
          # Built-in laptop display: stable workspaces
          workspace = 1, monitor:eDP-1, default:true, persistent:true
          workspace = 2, monitor:eDP-1, persistent:true
          workspace = 3, monitor:eDP-1, persistent:true
          workspace = 4, monitor:eDP-1, persistent:true
          workspace = 5, monitor:eDP-1, persistent:true

          # Samsung LF22T35 external: stable workspaces
          workspace = 6, monitor:desc:Samsung Electric Company LF22T35, default:true, persistent:true
          workspace = 7, monitor:desc:Samsung Electric Company LF22T35, persistent:true
          workspace = 8, monitor:desc:Samsung Electric Company LF22T35, persistent:true
          workspace = 9, monitor:desc:Samsung Electric Company LF22T35, persistent:true
          workspace = 10, monitor:desc:Samsung Electric Company LF22T35, persistent:true
        '';
      };
      nixosConfigurations.nuc = mkHost {
        machineModule = ./machine-nuc8i7hvk.nix;
        monitorsConfig = "monitor = ,preferred,auto-up,1\n";
      };
    };
}
