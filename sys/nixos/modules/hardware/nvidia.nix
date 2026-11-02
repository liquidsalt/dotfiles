{ ... }:
{
  hardware.graphics.enable = true;            # GPU drivers in /run/opengl-driver, where apps look for them

  hardware.nvidia = {
    open               = true;
    modesetting.enable = true;
  };

  services.xserver.videoDrivers = ["nvidia"]; # enables the NVIDIA drivers system-wide (needed for Wayland too)
}
