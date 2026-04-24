{ nvchad-starter }:
{ config, pkgs, ... }:
{
  home.stateVersion = "25.11";

  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  xdg.configFile = {
    "hypr/hyprland.conf".source = ./hyprland.conf;
    "waybar/config.jsonc".source = ./waybar-config.jsonc;
    "waybar/style.css".source = ./waybar-style.css;
    "mako/config".source = ./mako.conf;
    "foot/foot.ini".source = ./foot.ini;
    "nvim" = {
      source = nvchad-starter;
      recursive = true;
    };
  };
}
