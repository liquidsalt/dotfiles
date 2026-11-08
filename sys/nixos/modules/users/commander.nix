{ pkgs, ... }:
{
  users.users.commander = {
    isNormalUser = true;
    shell        = pkgs.fish;
    extraGroups  = [ "wheel" "networkmanager" ];
  };

  systemd.tmpfiles.rules = [
    "d /home/commander/downloads 0700 commander users -"

    "d /home/commander/documents 0700 commander users -"
    "d /home/commander/documents/notes 0700 commander users -"
    "d /home/commander/documents/gov 0700 commander users -"
    "d /home/commander/documents/finance 0700 commander users -"
    "d /home/commander/documents/school 0700 commander users -"
    "d /home/commander/documents/work 0700 commander users -"

    "d /home/commander/media 0700 commander users -"
    "d /home/commander/media/images 0700 commander users -"
    "d /home/commander/media/video 0700 commander users -"
    "d /home/commander/media/music 0700 commander users -"
    "d /home/commander/media/games 0700 commander users -"

    "d /home/commander/projects 0700 commander users -"
    "d /home/commander/projects/dev 0700 commander users -"
    "d /home/commander/projects/devops 0700 commander users -"
    "d /home/commander/projects/art 0700 commander users -"

    "d /home/commander/.secrets 0700 commander users -"
  ];
}
