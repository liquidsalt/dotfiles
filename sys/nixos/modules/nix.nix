{ ... }:
{
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };

  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";
}
