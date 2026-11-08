# Unsafe games run as player through `play`, inside gamescope with nothing of commander's session in reach
{ pkgs, ... }:
let
  play-inner = pkgs.writeShellApplication {
    name          = "play-inner";
    runtimeInputs = with pkgs; [ bubblewrap pulseaudio coreutils dbus ];
    text          = builtins.readFile ./play-inner.sh;
  };

  play = pkgs.writeShellApplication {
    name          = "play";
    runtimeInputs = with pkgs; [ pipewire coreutils gnused jq xhost systemd ];  # gamescope comes from programs.gamescope, hyprctl from the session
    text          = "play_inner=${play-inner}/bin/play-inner\n" + builtins.readFile ./play.sh;
  };
in
{
  users.groups.play = { };

  users.users.player = {
    isNormalUser = true;
    homeMode     = "710";  # commander can reach the shared folders but not list the home
    extraGroups  = [ "play" ];
  };
  users.users.commander.extraGroups = [ "play" ];

  # Never a desktop login of its own
  services.displayManager.sddm.settings.Users.HideUsers = "player";

  # commander may start play-inner as player and nothing else
  security.sudo.extraRules = [{
    users    = [ "commander" ];
    runAs    = "player";
    commands = [{ command = "${play-inner}/bin/play-inner"; options = [ "NOPASSWD" ]; }];
  }];

  environment.systemPackages = [ play ];

  # Gamepads reach games through the play group, keyboards and uinput never do or player could read or type into commander's session
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ENV{ID_INPUT_JOYSTICK}=="1", GROUP="play", MODE="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="28de|054c|057e|045e", GROUP="play", MODE="0660"
    KERNEL=="hidraw*", KERNELS=="*:28DE:*|*:054C:*|*:057E:*|*:045E:*", GROUP="play", MODE="0660"
  '';

  # setgid, so whatever commander drops in stays in play
  systemd.tmpfiles.rules = [
    "d /home/player/downloads 2770 player play -"

    "d /home/player/games 2770 player play -"
    "d /home/player/games/pc 2770 player play -"
    "d /home/player/games/ps4 2770 player play -"
    "d /home/player/games/switch 2770 player play -"
    "d /home/player/games/wiiu 2770 player play -"

    # One folder per running game, for its audio pipe
    "d /run/play 2770 commander play -"
  ];
}
