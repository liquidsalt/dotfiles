{ ... }:
{
  services.displayManager.sddm = {
    enable         = true;
    wayland.enable = true;

    # The applied profile puts its theme here, SDDM falls back to its own while it's empty
    theme = "profile";
    settings.Theme.ThemeDir = "/var/lib/dotfiles/sddm";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/dotfiles 0755 root root -"
    "d /var/lib/dotfiles/sddm 0755 root root -"
    "d /var/lib/dotfiles/sddm/profile 0755 commander users -"
  ];
}
