{ nvchad-starter, monitorsConfig, workspacesConfig }:
{ config, lib, pkgs, ... }:
{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    bibata-cursors
    mermaid-cli
    nodejs_22
  ];

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.config/nixy"
  ];

  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "20";
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 20;
    gtk.enable = true;
    x11.enable = true;
  };

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

  home.file.".vscode/argv.json" = {
    text = builtins.toJSON {
      disable-hardware-acceleration = true;
      enable-crash-reporter = false;
      password-store = "basic";
    };
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
    gtk4.theme = config.gtk.theme;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Allain Lalonde";
        email = "allain.lalonde@gmail.com";
      };
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
        "PATH=${lib.makeBinPath (with pkgs; [ bash awww coreutils curl findutils gnugrep gnused ])}"
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

  # Walker 2.x split its data layer into a separate `elephant` backend daemon.
  # Without elephant running, walker exits immediately with
  # "Please install elephant" and Super+Space silently does nothing.
  systemd.user.services.elephant = {
    Unit = {
      Description = "Elephant data provider (walker backend)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.elephant}/bin/elephant";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Walker launcher daemon. Managed by systemd so it auto-restarts if it
  # crashes (previously relied on `exec-once` which only fires once per
  # Hyprland session — if walker died mid-session, Super+Space stopped
  # working until logout).
  systemd.user.services.walker = {
    Unit = {
      Description = "Walker application launcher (GApplication service)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "elephant.service" ];
      Requires = [ "elephant.service" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.activation.renderTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${lib.makeBinPath (with pkgs; [ bash coreutils gettext gnused gnugrep ])}:$PATH"

    CURRENT_THEME_FILE="${config.home.homeDirectory}/.config/nixy/current-theme"
    THEME="catppuccin-mocha"

    if [ -f "$CURRENT_THEME_FILE" ]; then
      THEME="$(cat "$CURRENT_THEME_FILE")"
    fi

    # No `|| true`: render failures must abort activation so stale configs
    # (e.g. old windowrulev2 syntax) never linger across rebuilds.
    $DRY_RUN_CMD bash "${config.home.homeDirectory}/.config/nixy/theme-set" --no-reload "$THEME"
  '';

  xdg.configFile = {
    # Non-themed configs (no colors, deployed directly)
    "waybar/config.jsonc".source = ./waybar-config.jsonc;
    "walker/config.toml".source = ./walker-config.toml;
    "walker/themes/catppuccin.json".source = ./walker-theme.json;
    "hypr/hypridle.conf".source = ./hypridle.conf;
    "hypr/workspaces.conf" = {
      text = workspacesConfig;
      force = true;
    };
    "hypr/walker-bitwarden.sh" = {
      source = ./walker-bitwarden.sh;
      executable = true;
    };
    "hypr/open-terminal.sh" = {
      source = ./open-terminal.sh;
      executable = true;
    };
    "hypr/cursor-zoom-toggle.sh" = {
      source = ./cursor-zoom-toggle.sh;
      executable = true;
    };
    "uwsm/env".text = ''
      export XCURSOR_THEME=Bibata-Modern-Classic
      export XCURSOR_SIZE=20
    '';
    "nvim" = {
      source = nvchad-starter;
      recursive = true;
    };

    # Theme switcher script
    "nixy/theme-set" = {
      source = ./theme-set.sh;
      executable = true;
    };

    "nixy/brightness-menu" = {
      source = ./brightness-menu.sh;
      executable = true;
    };

    "nixy/power-menu" = {
      source = ./power-menu.sh;
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
    "nixy/themes/catppuccin-latte.sh".source = ./themes/catppuccin-latte.sh;
    "nixy/themes/tokyo-night.sh".source = ./themes/tokyo-night.sh;
    "nixy/themes/nord.sh".source = ./themes/nord.sh;
    "nixy/themes/gruvbox-dark.sh".source = ./themes/gruvbox-dark.sh;
    "nixy/themes/gruvbox-light.sh".source = ./themes/gruvbox-light.sh;
    "nixy/themes/rose-pine.sh".source = ./themes/rose-pine.sh;
    "nixy/themes/rose-pine-dawn.sh".source = ./themes/rose-pine-dawn.sh;
    "nixy/themes/dracula.sh".source = ./themes/dracula.sh;
    "nixy/themes/one-dark.sh".source = ./themes/one-dark.sh;
    "nixy/themes/solarized-dark.sh".source = ./themes/solarized-dark.sh;
    "nixy/themes/solarized-light.sh".source = ./themes/solarized-light.sh;
    "nixy/themes/everforest-dark.sh".source = ./themes/everforest-dark.sh;
    "nixy/themes/everforest-light.sh".source = ./themes/everforest-light.sh;
    "nixy/themes/kanagawa.sh".source = ./themes/kanagawa.sh;
  };
}
