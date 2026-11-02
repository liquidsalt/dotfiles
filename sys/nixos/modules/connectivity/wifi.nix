{ ... }:
{
  networking.networkmanager.ensureProfiles.profiles = {
    home-wifi = {
      connection = {
        id = "home-wifi";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "BELL096";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "9FCC749DC624";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };

    pod002-hotspot = {
      connection = {
        id = "pod002-hotspot";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "Pod 002";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "Jduc3ey7wu";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };
}
