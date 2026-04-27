{ nvchad-starter, monitorScale, monitorPosition }:
{ config, lib, pkgs, ... }:
{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    nodejs_22
  ];

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.npm-global/bin"
  ];

  programs.bash = {
    enable = true;
    initExtra = ''
      . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
    '';
  };

  home.file.".npmrc" = {
    text = "prefix=${config.home.homeDirectory}/.npm-global\n";
    force = true;
  };

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
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  xdg.configFile = {
    "hypr/hyprland.conf".source = ./hyprland.conf;
    "hypr/monitors.conf".text = "monitor = ,preferred,${monitorPosition},${toString monitorScale}\n";
    "waybar/config.jsonc".source = ./waybar-config.jsonc;
    "waybar/style.css".source = ./waybar-style.css;
    "mako/config".source = ./mako.conf;
    "foot/foot.ini".source = ./foot.ini;
    "walker/config.toml".source = ./walker-config.toml;
    "hypr/walker-bitwarden.sh" = {
      source = ./walker-bitwarden.sh;
      executable = true;
    };
    "hypr/retile.sh" = {
      source = ./retile.sh;
      executable = true;
    };
    "nvim" = {
      source = nvchad-starter;
      recursive = true;
    };
  };
}
