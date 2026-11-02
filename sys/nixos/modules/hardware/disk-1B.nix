{ ... }:
{
  disko.devices.disk.main = {
    type   = "disk";
    device = "/dev/nvme0n1";

    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          size     = "1G";
          type     = "EF00";
          content = {
            type         = "filesystem";
            format       = "vfat";
            mountpoint   = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          priority = 2;
          size     = "800G";
          content = {
            type = "luks";
            name = "cryptroot";
            passwordFile = "/tmp/disk-password";  # only read while formatting, install.sh writes it
            settings.allowDiscards     = true;
            settings.crypttabExtraOpts = [ "password-echo=yes" ];
            content = {
              type       = "filesystem";
              format     = "ext4";
              mountpoint = "/";
            };
          };
        };

        swap = {
          priority = 3;
          size     = "20G";
          content = {
            type             = "swap";
            randomEncryption = true;  # makes hibernate impossible
          };
        };
      };
    };
  };
}
