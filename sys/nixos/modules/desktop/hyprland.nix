{ lib, pkgs, ... }:
{
  programs.hyprland = {
    enable          = true;
    xwayland.enable = true;
    withUWSM        = true;
  };

  programs.hyprlock.enable = true;
  services.hypridle.enable = lib.mkForce false;  # hyprlock's module turns it on, locking is manual only

  environment.systemPackages = with pkgs; [
    xrandr           # hyprland.lua sets the primary monitor for X11 games with it
  ];
}
