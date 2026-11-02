# Unsafe games run as player, started from commander with sudo -u player
{ ... }:
{
  users.groups.play = { };

  users.users.player = {
    isNormalUser = true;
    homeMode     = "710";  # commander can reach the shared folders but not list the home
  };
  users.users.commander.extraGroups = [ "play" ];

  # Never a desktop login of its own
  services.displayManager.sddm.settings.Users.HideUsers = "player";

  # setgid, so whatever commander drops in stays in play
  systemd.tmpfiles.rules = [
    "d /home/player/downloads 2770 player play -"

    "d /home/player/games 2770 player play -"
    "d /home/player/games/pc 2770 player play -"
    "d /home/player/games/ps4 2770 player play -"
    "d /home/player/games/switch 2770 player play -"
  ];
}
