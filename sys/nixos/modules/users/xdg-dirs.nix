# System-wide, so it's set once here and not per user
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.xdg-user-dirs ];

  environment.etc."xdg/user-dirs.defaults".text = ''
    DOWNLOAD=downloads
    DOCUMENTS=documents
    PICTURES=media/images
    VIDEOS=media/video
    MUSIC=media/music
  '';
}
