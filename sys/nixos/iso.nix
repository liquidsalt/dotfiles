{ modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./modules/connectivity/wifi.nix
  ];

  networking.hostName = "installer";

  # nixos-install --flake needs these and the CD doesn't enable them
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  boot.supportedFilesystems.zfs = false;  # ext4 only, and it shrinks the image

  # Leave networking.wireless alone, NetworkManager runs wpa_supplicant through it and turning it off removes the wifi device

  services.tailscale = {
    enable = true;
    extraDaemonFlags = [ "--state=mem:" ];  # node key in RAM, so logout is final
  };

  environment.systemPackages = with pkgs; [
    (pkgs.writeShellScriptBin "install-1B" (builtins.readFile ../../install.sh))
    age
    curl
    git
    gptfdisk
    jq
    tailscale
    zstd
  ];

  services.getty.helpLine = ''

    Type `sudo install-1B` to install.
  '';
}
