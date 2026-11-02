{ lib, ... }:
{
  boot.kernelParams = [ "mem_sleep_default=deep" ];
  services.logind.settings.Login = {
    HandleLidSwitch              = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };

  specialisation.docked.configuration = {
    systemd.targets = {
      sleep.enable        = false;
      suspend.enable      = false;
      hibernate.enable    = false;
      hybrid-sleep.enable = false;
    };
    services.logind.settings.Login.HandleLidSwitch = lib.mkForce "ignore";

    boot.kernelParams = [ "video=eDP-1:d" ];  # laptop screen off while docked
  };
}
