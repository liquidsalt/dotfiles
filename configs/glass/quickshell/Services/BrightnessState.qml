pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    property int brightness:    0
    property int maxBrightness: 100
    readonly property int percent: maxBrightness > 0 ? Math.round(brightness / maxBrightness * 100) : 0

    // The kernel docs say to prefer firmware over platform over raw
    readonly property var preference: ["firmware", "platform", "raw"]
    property var types: ({})

    readonly property string base: {
        var best = "", rank = 99;
        for (var name in root.types) {
            var r = root.preference.indexOf(root.types[name]);
            if (r >= 0 && r < rank) { rank = r; best = "/sys/class/backlight/" + name; }
        }
        return best;
    }

    SysDir { id: backlights; path: "/sys/class/backlight" }

    Instantiator {
        model: backlights.names
        delegate: FileView {
            path: "/sys/class/backlight/" + modelData + "/type"
            onLoaded: {
                var next = ({});
                for (var k in root.types) next[k] = root.types[k];
                next[modelData] = text().trim();
                root.types = next;
            }
        }
    }

    FileView {
        path: root.base ? root.base + "/brightness" : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var v = parseInt(text().trim(), 10);
            if (!isNaN(v)) root.brightness = v;
        }
    }

    FileView {
        path: root.base ? root.base + "/max_brightness" : ""
        onLoaded: {
            var v = parseInt(text().trim(), 10);
            if (!isNaN(v)) root.maxBrightness = v;
        }
    }
}
