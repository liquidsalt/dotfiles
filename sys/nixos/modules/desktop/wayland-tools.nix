{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    grim          # screenshot capture
    slurp         # region selection
    wl-clipboard  # clipboard
  ];
}
