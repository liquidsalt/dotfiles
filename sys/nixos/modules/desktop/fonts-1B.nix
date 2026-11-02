{ pkgs, ... }:
{
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Adwaita Sans" ];
    serif     = [ "Literata" ];
    monospace = [ "IBM Plex Mono" ];
    emoji     = [ "Twitter Color Emoji" ];
  };

  fonts.packages = with pkgs; [
    adwaita-fonts           # sans font
    literata                # serif font
    (ibm-plex               # mono font
        .override {families = [ "mono" ];})
    fira-mono               # code/terminal font

    # compatibility
    noto-fonts              # default fallback
    twitter-color-emoji     # emojis
    noto-fonts-cjk-sans     # chinese/korean/japanese
    liberation_ttf          # times new roman and others
    nerd-fonts.symbols-only # nerd fonts icons
    material-symbols        # quickshell bar icons
  ];
}
