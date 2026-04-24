{ config, lib, pkgs, self, ... }:
let
  identity = import ./identity.nix;
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./machine-mach-w29.nix
  ];

  system.stateVersion = "25.11";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "l2tp_ppp" "l2tp_netlink" "ppp_generic" ];

  networking.hostName = identity.hostName;
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-l2tp
    ];
  };

  time.timeZone = identity.timeZone;
  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "us";

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };

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
    glow
    jq
    lazygit
    lazydocker
    libnotify
    mako
    mattermost-desktop
    neovim
    networkmanagerapplet
    strongswan
    xl2tpd
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

  documentation.man.enable = true;
  documentation.doc.enable = false;
  documentation.info.enable = false;

  virtualisation.docker.enable = true;

  # Auto-mount USB drives at /mnt/usb
  services.udisks2.enable = true;
  systemd.tmpfiles.rules = [
    "d /mnt/usb 0755 ${identity.userName} users -"
    "d /etc/ipsec.d 0755 root root -"
  ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", ENV{ID_USB_DRIVER}=="usb-storage", ENV{DEVTYPE}=="partition", TAG+="systemd", ENV{SYSTEMD_WANTS}+="usb-automount@%k.service"
  '';
  systemd.services."usb-automount@" = {
    description = "Auto-mount USB device /dev/%i to /mnt/usb";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.util-linux}/bin/mount -o rw,sync /dev/%i /mnt/usb";
      ExecStart = "${pkgs.coreutils}/bin/chown -R ${identity.userName}:users /mnt/usb";
      ExecStop = "${pkgs.util-linux}/bin/umount /mnt/usb";
    };
  };

  services.strongswan.enable = true;

  environment.etc."strongswan.conf".text = ''
    charon {
      integrity_test = no
      load_modular = no
    }
  '';

  services.openssh.enable = false;
  zramSwap.enable = true;
}
