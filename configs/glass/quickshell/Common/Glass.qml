pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property color ink: "#05070B"

    readonly property color panel:       Qt.rgba(0.071, 0.082, 0.110, 0.44)
    readonly property color panelStrong: Qt.rgba(0.071, 0.082, 0.110, 0.88)

    readonly property color stroke: Qt.rgba(1, 1, 1, 0.11)
    readonly property color hover:  Qt.rgba(1, 1, 1, 0.10)

    readonly property color text:     "#EDF0F5"
    readonly property color muted:    Qt.rgba(0.929, 0.941, 0.961, 0.56)
    readonly property color faint:    Qt.rgba(0.929, 0.941, 0.961, 0.28)
    readonly property color critical: "#FF8A80"
    readonly property color accent:   "#E2C9A2"

    readonly property color cool: "#7BD88F"
    readonly property color warm: "#E8913A"
    readonly property color fire: "#FF5A3C"

    // Green at 40 °C, orange once within 5 °C of the chip's limit
    function heat(temp, limit) {
        if (limit <= 0) return root.cool;
        var t = Math.max(0, Math.min(1, (temp - 40) / Math.max(1, limit - 45)));
        return Qt.rgba(root.cool.r + (root.warm.r - root.cool.r) * t,
                       root.cool.g + (root.warm.g - root.cool.g) * t,
                       root.cool.b + (root.warm.b - root.cool.b) * t, 1);
    }

    function overheating(temp, limit) { return limit > 0 && temp >= limit - 5; }

    // Generic names resolve through fontconfig.defaultFonts in fonts-1B.nix
    readonly property string fontUi:    "sans-serif"
    readonly property string fontMono:  "monospace"
    readonly property string fontIcon:  "Material Symbols Rounded"
    readonly property string fontGlyph: "Symbols Nerd Font"  // glyphs Material Symbols lacks

    readonly property var tnum: ({ "tnum": 1 })

    function icon(fill, weight) {
        return { "FILL": fill, "wght": weight, "GRAD": 0, "opsz": 24 };
    }
    readonly property var iconIdle:   root.icon(0.0, 300)
    readonly property var iconActive: root.icon(1.0, 350)

    readonly property int barZone:    50  // space reserved for the bar
    readonly property int barHeight:  34  // the drawn panel
    readonly property int barMargin:  12  // gap left and right
    readonly property int barTop:     10  // gap above the panel
    readonly property int barRadius:  12

    readonly property int popupRadius:    14
    readonly property int launcherWidth:  520
    readonly property int launcherRadius: 18
    readonly property int rowHeight:      40
    readonly property int rowRadius:      11
}
