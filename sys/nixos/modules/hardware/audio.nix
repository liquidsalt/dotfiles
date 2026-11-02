{ pkgs, ... }:
{
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };
  security.rtkit.enable = true;

  environment.systemPackages =  with pkgs; [ pavucontrol ];
}
