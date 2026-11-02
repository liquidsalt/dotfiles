{ ... }:
{
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 22 ];
}
