{ ... }:
{
  imports = [
    ./intel.nix

    ./nvidia.nix
    ./nvidia-1B.nix

    ./audio.nix

    ./power.nix
    ./power-1B.nix

    ./brightness.nix
    ./firmware.nix

    ./disk-1B.nix

    ./peripherals/1B.nix
  ];
}
