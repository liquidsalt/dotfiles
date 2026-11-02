{ ... }:
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--accept-dns=true" ];  # MagicDNS for tailnet names
  };
  services.resolved.enable = true;  # tailnet names go to tailscale, everything else to the wifi DNS
}
