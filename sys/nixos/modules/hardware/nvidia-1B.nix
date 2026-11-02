{ lib, ... }:
{
  # Undocked, the iGPU renders
  hardware.nvidia.prime = {
    offload.enable           = true;
    offload.enableOffloadCmd = true;
    intelBusId  = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # Docked, the dGPU renders
  specialisation.docked.configuration = {
    system.nixos.tags = [ "docked" ];
    hardware.nvidia.prime = {
      offload.enable           = lib.mkForce false;
      offload.enableOffloadCmd = lib.mkForce false;
      sync.enable              = lib.mkForce true;
    };

    # ATTRS would also match the Intel PCI bridge above the NVIDIA card, so this checks the card itself
    services.udev.extraRules = ''
      KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ATTR{device/vendor}=="0x10de", SYMLINK+="dri/nvidia-dgpu", TAG+="mutter-device-preferred-primary"
      KERNEL=="card[0-9]*", SUBSYSTEM=="drm", ATTR{device/vendor}=="0x8086", SYMLINK+="dri/intel-igpu"
    '';

    environment.sessionVariables = {
      AQ_DRM_DEVICES   = "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu";
      WLR_DRM_DEVICES  = "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu";
      KWIN_DRM_DEVICES = "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu";
    };
  };
}
