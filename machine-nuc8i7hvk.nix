{ pkgs, ... }:
{
  networking.hostName = "nuc";

  boot.kernelParams = [
    "quiet"
    "loglevel=3"
  ];

  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Intel HD Graphics 630
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  # Ensure both amdgpu and i915 are loaded
  boot.initrd.kernelModules = [ "amdgpu" "i915" ];

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
  };
}
