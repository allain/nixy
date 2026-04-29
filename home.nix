{ nvchad-starter, monitorsConfig }:
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

  home.activation.seedMonitorsConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MONITORS_CONF="${config.home.homeDirectory}/.config/hypr/monitors.conf"
    if [ ! -f "$MONITORS_CONF" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$MONITORS_CONF")"
      $DRY_RUN_CMD cat > "$MONITORS_CONF" << 'EOF'
${monitorsConfig}
EOF
    fi
  '';

  home.activation.installOpenAICodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global"
    export PATH="${pkgs.nodejs_22}/bin:$NPM_CONFIG_PREFIX/bin:$PATH"

    $DRY_RUN_CMD mkdir -p "$NPM_CONFIG_PREFIX"

    if [ ! -x "$NPM_CONFIG_PREFIX/bin/codex" ]; then
      $DRY_RUN_CMD ${pkgs.nodejs_22}/bin/npm install --global @openai/codex
    fi
  '';

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  systemd.user.services.bing-wallpaper = {
    Unit.Description = "Fetch and set Bing daily wallpaper";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/hypr/bing-wallpaper.sh";
      Environment = [
        "PATH=${lib.makeBinPath (with pkgs; [ curl jq swww coreutils findutils ])}"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
    };
  };

  systemd.user.timers.bing-wallpaper = {
    Unit.Description = "Fetch Bing wallpaper daily";
    Timer = {
      OnCalendar = "*-*-* 08:00:00";
      OnStartupSec = "30";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  xdg.configFile = {
    "hypr/hyprland.conf".source = ./hyprland.conf;
    "waybar/config.jsonc".source = ./waybar-config.jsonc;
    "waybar/style.css".source = ./waybar-style.css;
    "mako/config".source = ./mako.conf;
    "foot/foot.ini".source = ./foot.ini;
    "walker/config.toml".source = ./walker-config.toml;
    "walker/themes/catppuccin.json".source = ./walker-theme.json;
    "walker/themes/catppuccin.css".source = ./walker-style.css;
    "hypr/walker-bitwarden.sh" = {
      source = ./walker-bitwarden.sh;
      executable = true;
    };
    "hypr/bing-wallpaper.sh" = {
      source = ./bing-wallpaper.sh;
      executable = true;
    };
    "hypr/workspace-manager.sh" = {
      source = ./workspace-manager.sh;
      executable = true;
    };
    "nvim" = {
      source = nvchad-starter;
      recursive = true;
    };
  };
}
