{ pkgs, ... }:
{
  # The unit itself is in the profile, configs/glass/systemd/quickshell.service
  environment.systemPackages = [ pkgs.quickshell ];
}
