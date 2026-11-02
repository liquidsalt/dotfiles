{ ... }:
{
  imports = [
    ./networking.nix
    ./networking-1B.nix
    ./wifi.nix

    ./bluetooth.nix

    ./firewall.nix
    ./firewall-1B.nix

    ./ssh.nix
    ./ssh-1B.nix

    ./tailscale.nix
  ];
}
