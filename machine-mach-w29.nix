{ pkgs, ... }:
{
  # Keep machine-specific laptop choices here rather than in
  # hardware-configuration.nix so they can be versioned and copied safely.

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
  ];

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
