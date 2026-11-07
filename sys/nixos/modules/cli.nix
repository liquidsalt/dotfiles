{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    neovim    # text editor
    yazi      # file manager
    starship  # prompt

    btop      # hardware utilization and task manager
    fastfetch # distro info display

    # archives
    zstd
    gnutar
    unar

    age       # encryption tool
    restic    # dotfiles backup runs on it

    # utilities
    fd
    ripgrep
    jq

    python3   # dotfiles runs on it
  ];

  programs.fish.enable = true;
  programs.git.enable  = true;  # dotfiles fetches through it

  environment.localBinInPath = true;  # ~/.local/bin, where dotfiles goes
}
