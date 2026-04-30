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
    "$HOME/.config/nixy"
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
    userName = "Allain Lalonde";
    userEmail = "allain.lalonde@gmail.com";
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  systemd.user.services.wallpaper = {
    Unit.Description = "Set random wallpaper";
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.config/nixy/wallpaper";
      Environment = [
        "PATH=${lib.makeBinPath (with pkgs; [ swww coreutils curl gnugrep gnused ])}"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_RUNTIME_DIR=/run/user/1000"
      ];
    };
  };

  systemd.user.timers.wallpaper = {
    Unit.Description = "Change wallpaper daily";
    Timer = {
      OnCalendar = "daily";
      OnStartupSec = "5s";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.activation.bootstrapTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${config.home.homeDirectory}/.config/nixy/current-theme" ]; then
      $DRY_RUN_CMD bash "${config.home.homeDirectory}/.config/nixy/theme-set" catppuccin-mocha || true
    fi
  '';

  xdg.configFile = {
    # Non-themed configs (no colors, deployed directly)
    "waybar/config.jsonc".source = ./waybar-config.jsonc;
    "walker/config.toml".source = ./walker-config.toml;
    "walker/themes/catppuccin.json".source = ./walker-theme.json;
    "hypr/hypridle.conf".source = ./hypridle.conf;
    "hypr/walker-bitwarden.sh" = {
      source = ./walker-bitwarden.sh;
      executable = true;
    };
    "hypr/open-terminal.sh" = {
      source = ./open-terminal.sh;
      executable = true;
    };
    "nvim" = {
      source = nvchad-starter;
      recursive = true;
    };

    # Theme switcher script
    "nixy/theme-set" = {
      source = ./theme-set.sh;
      executable = true;
    };

    # Wallpaper picker script
    "nixy/wallpaper" = {
      source = ./wallpaper.sh;
      executable = true;
    };

    # Templates
    "nixy/templates/hyprland.conf.tpl".source = ./templates/hyprland.conf.tpl;
    "nixy/templates/waybar-style.css.tpl".source = ./templates/waybar-style.css.tpl;
    "nixy/templates/foot.ini.tpl".source = ./templates/foot.ini.tpl;
    "nixy/templates/mako.conf.tpl".source = ./templates/mako.conf.tpl;
    "nixy/templates/hyprlock.conf.tpl".source = ./templates/hyprlock.conf.tpl;
    "nixy/templates/walker-style.css.tpl".source = ./templates/walker-style.css.tpl;

    # Themes
    "nixy/themes/catppuccin-mocha.sh".source = ./themes/catppuccin-mocha.sh;
    "nixy/themes/tokyo-night.sh".source = ./themes/tokyo-night.sh;
    "nixy/themes/nord.sh".source = ./themes/nord.sh;
    "nixy/themes/gruvbox-dark.sh".source = ./themes/gruvbox-dark.sh;
    "nixy/themes/rose-pine.sh".source = ./themes/rose-pine.sh;
    "nixy/themes/dracula.sh".source = ./themes/dracula.sh;
    "nixy/themes/one-dark.sh".source = ./themes/one-dark.sh;
    "nixy/themes/solarized-dark.sh".source = ./themes/solarized-dark.sh;
    "nixy/themes/everforest-dark.sh".source = ./themes/everforest-dark.sh;
    "nixy/themes/kanagawa.sh".source = ./themes/kanagawa.sh;
  };
}
