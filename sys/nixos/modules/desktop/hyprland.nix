{ pkgs, ... }:
{
  programs.hyprland = {
    enable          = true;
    xwayland.enable = true;
    withUWSM        = true;
  };

  programs.hyprlock.enable = true;

  environment.systemPackages = with pkgs; [
    xrandr           # hyprland.lua sets the primary monitor for X11 games with it
  ];
}
