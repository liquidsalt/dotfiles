# The boot menu says Docked and Undocked instead of NixOS's generation names
{ pkgs, ... }:
let
  names = pkgs.writeText "boot-1B.pl" (builtins.readFile ./boot-1B.pl);
in
{
  # Runs right after NixOS writes the menu, if it fails the menu keeps NixOS's names and the rebuild still goes through
  boot.loader.grub.extraInstallCommands = ''
    ${pkgs.perl}/bin/perl ${names} /boot/grub/grub.cfg || echo "boot menu names left as NixOS wrote them" >&2
  '';
}
