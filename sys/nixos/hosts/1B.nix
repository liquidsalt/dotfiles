{ ... }:
{
  imports = [
    ../modules/nix.nix
    ../modules/boot.nix
    ../modules/boot-1B.nix

    ../modules/hardware/1B.nix
    ../modules/connectivity/1B.nix

    ../modules/locale.nix

    ../modules/users/1B.nix

    ../modules/cli.nix
    ../modules/dev.nix

    ../modules/desktop/1B.nix

    ../modules/apps.nix
  ];
}
