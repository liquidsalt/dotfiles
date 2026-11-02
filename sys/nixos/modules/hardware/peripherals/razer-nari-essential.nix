{ pkgs, ... }:
{
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "70-nari-essential.rules";
      destination = "/lib/udev/rules.d/70-nari-essential.rules";
      text = ''
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="051e", TAG+="uaccess"
        SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="051f", TAG+="uaccess"
      '';
    })
  ];
}
