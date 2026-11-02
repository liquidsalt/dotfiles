{ ... }:
{
  imports = [
    ./sddm.nix
    ./hyprland.nix
    ./quickshell.nix
    ./keyring.nix
    ./wayland-tools.nix

    ./fonts-1B.nix
    ./theme-1B.nix
  ];
}
