{ pkgs, lib, ... }:
{
  # Keep machine-specific laptop choices here rather than in
  # hardware-configuration.nix so they can be versioned and copied safely.

  networking.hostName = "mach-w29";

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
  ];

  # Hibernate support — Huawei Matebook specific
  boot.resumeDevice = "/dev/disk/by-uuid/84204633-b192-41d8-ac99-a6091d5736c2";

  swapDevices = lib.mkForce [
    {
      device = "/dev/disk/by-uuid/84204633-b192-41d8-ac99-a6091d5736c2";
      priority = 100;
    }
  ];

  # Use 'shutdown' hibernate mode instead of platform/ACPI S4.
  # Huawei Matebook firmware is unreliable with platform S4; shutdown mode
  # just writes the image and powers off, then resumes on next boot.
  systemd.tmpfiles.rules = [
    "w /sys/power/disk - - - - shutdown"
  ];

  # Force disk swap priority above zram so disk swap is consumed first,
  # avoiding zram interfering with the hibernation snapshot.
  zramSwap.priority = 5;

  # Belt-and-suspenders: swapoff zram before hibernate, swapon after resume.
  systemd.services.zram-hibernate-fix = {
    description = "Disable zram around hibernate";
    wantedBy = [
      "systemd-hibernate.service"
      "systemd-suspend-then-hibernate.service"
      "systemd-hybrid-sleep.service"
    ];
    before = [
      "systemd-hibernate.service"
      "systemd-suspend-then-hibernate.service"
      "systemd-hybrid-sleep.service"
    ];
    unitConfig.StopWhenUnneeded = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.util-linux}/bin/swapoff /dev/zram0";
      ExecStop = "${pkgs.util-linux}/bin/swapon --priority -10 /dev/zram0";
    };
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
  };

  services.libinput.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [
    pkgs.sof-firmware
  ];
  hardware.graphics.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
  };

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
}
