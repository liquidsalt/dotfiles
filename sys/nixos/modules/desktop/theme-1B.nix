{ pkgs, ... }:
{
  programs.dconf.enable = true;  # the profile loads its theme into dconf

  # GTK reads dconf through these schemas
  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme  # gtk icons and cursor
    gnome-themes-extra  # Adwaita-dark for GTK3, which only ships the light one
  ];
}
