{ config, lib, pkgs, self, nvchad-starter, ... }:
let
  identity = import ./identity.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ./machine-mach-w29.nix
  ];

  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = identity.hostName;
  networking.networkmanager.enable = true;

  time.timeZone = identity.timeZone;
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "us";

  security.rtkit.enable = true;

  services.dbus.enable = true;
  security.polkit.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'uwsm start hyprland-uwsm.desktop'";
      user = "greeter";
    };
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  programs.uwsm.enable = true;
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  environment.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "foot";
    BROWSER = "google-chrome-stable";
    NIXOS_OZONE_WL = "1";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    C_INCLUDE_PATH = "${pkgs.openssl.dev}/include";
    LIBRARY_PATH = "${pkgs.lib.getLib pkgs.openssl}/lib";
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    curl
    claude-code-bin
    deno
    fd
    google-chrome
    foot
    git
    glow
    jq
    lazygit
    lazydocker
    libnotify
    mako
    mattermost-desktop
    neovim
    networkmanagerapplet
    nodejs_22
    openssl
    openssl.dev
    pkg-config
    pavucontrol
    playerctl
    ripgrep
    python3
    psmisc
    unzip
    vim
    waybar
    wget
    wl-clipboard
    vscode
    wofi
    zigpkgs."0.16.0"
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  users.mutableUsers = true;
  users.users.${identity.userName} = {
    isNormalUser = true;
    description = identity.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
      "docker"
    ];
    initialPassword = identity.initialPassword;
  };

  programs.bash.shellAliases = {};

  system.activationScripts.installUserBootstrap.text = ''
    install -d -m 0755 /etc/skel/.config/nixpkgs
    install -d -m 0755 /etc/skel/.config/hypr
    install -d -m 0755 /etc/skel/.config/waybar
    install -d -m 0755 /etc/skel/.config/mako
    install -d -m 0755 /etc/skel/.config/foot

    cp -r ${nvchad-starter}/ /etc/skel/.config/nvim
    cp ${./hyprland.conf} /etc/skel/.config/hypr/hyprland.conf
    cp ${./waybar-config.jsonc} /etc/skel/.config/waybar/config.jsonc
    cp ${./waybar-style.css} /etc/skel/.config/waybar/style.css
    cp ${./mako.conf} /etc/skel/.config/mako/config
    cp ${./foot.ini} /etc/skel/.config/foot/foot.ini

    install -d -m 0755 /usr/local/bin
    cat > /usr/local/bin/install-claude-code <<'EOF'
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="$HOME/.local/bin:$PATH"
    curl -fsSL https://claude.ai/install.sh | bash
    EOF
    chmod 0755 /usr/local/bin/install-claude-code

    if id -u ${identity.userName} >/dev/null 2>&1; then
      install -d -o ${identity.userName} -g users -m 0755 /home/${identity.userName}/.config/hypr
      install -d -o ${identity.userName} -g users -m 0755 /home/${identity.userName}/.config/waybar
      install -d -o ${identity.userName} -g users -m 0755 /home/${identity.userName}/.config/mako
      install -d -o ${identity.userName} -g users -m 0755 /home/${identity.userName}/.config/foot

      if [ ! -e /home/${identity.userName}/.config/hypr/hyprland.conf ]; then
        cp ${./hyprland.conf} /home/${identity.userName}/.config/hypr/hyprland.conf
        chown ${identity.userName}:users /home/${identity.userName}/.config/hypr/hyprland.conf
      fi

      if [ ! -e /home/${identity.userName}/.config/waybar/config.jsonc ]; then
        cp ${./waybar-config.jsonc} /home/${identity.userName}/.config/waybar/config.jsonc
        chown ${identity.userName}:users /home/${identity.userName}/.config/waybar/config.jsonc
      fi

      if [ ! -e /home/${identity.userName}/.config/waybar/style.css ]; then
        cp ${./waybar-style.css} /home/${identity.userName}/.config/waybar/style.css
        chown ${identity.userName}:users /home/${identity.userName}/.config/waybar/style.css
      fi

      if [ ! -e /home/${identity.userName}/.config/mako/config ]; then
        cp ${./mako.conf} /home/${identity.userName}/.config/mako/config
        chown ${identity.userName}:users /home/${identity.userName}/.config/mako/config
      fi

      if [ ! -e /home/${identity.userName}/.config/foot/foot.ini ]; then
        cp ${./foot.ini} /home/${identity.userName}/.config/foot/foot.ini
        chown ${identity.userName}:users /home/${identity.userName}/.config/foot/foot.ini
      fi

      if [ ! -e /home/${identity.userName}/.config/nvim/init.lua ]; then
        install -d -o ${identity.userName} -g users -m 0755 /home/${identity.userName}/.config/nvim
        cp -r ${nvchad-starter}/* /home/${identity.userName}/.config/nvim/
        chown -R ${identity.userName}:users /home/${identity.userName}/.config/nvim
      fi
    fi
  '';

  documentation.man.enable = true;
  documentation.doc.enable = false;
  documentation.info.enable = false;

  virtualisation.docker.enable = true;

  # Auto-mount USB drives at /mnt/usb
  services.udisks2.enable = true;
  systemd.tmpfiles.rules = [
    "d /mnt/usb 0755 root root -"
  ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", ENV{ID_USB_DRIVER}=="usb-storage", ENV{DEVTYPE}=="partition", TAG+="systemd", ENV{SYSTEMD_WANTS}+="usb-automount@%k.service"
  '';
  systemd.services."usb-automount@" = {
    description = "Auto-mount USB device /dev/%i to /mnt/usb";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.util-linux}/bin/mount -o rw,sync /dev/%i /mnt/usb";
      ExecStop = "${pkgs.util-linux}/bin/umount /mnt/usb";
    };
  };

  services.openssh.enable = false;
  zramSwap.enable = true;
}
