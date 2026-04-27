{ nvchad-starter }:
{ config, lib, pkgs, ... }:
{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    nodejs_22
  ];

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  home.file.".npmrc".text = "prefix=${config.home.homeDirectory}/.npm-global\n";

  home.activation.installOpenAICodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global"
    export PATH="${pkgs.nodejs_22}/bin:$NPM_CONFIG_PREFIX/bin:$PATH"

    $DRY_RUN_CMD mkdir -p "$NPM_CONFIG_PREFIX"

    if [ ! -x "$NPM_CONFIG_PREFIX/bin/codex" ]; then
      $DRY_RUN_CMD ${pkgs.nodejs_22}/bin/npm install --global @openai/codex
    fi
  '';

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
