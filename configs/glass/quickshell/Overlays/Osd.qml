import Quickshell
import QtQuick
import "../Services"
import "../Widgets"

Scope {
    OsdPill {
        id: brightness
        glyph:   ""
        percent: BrightnessState.percent

        // Skip the first read at startup so the OSD doesn't pop up
        property bool primed: false

        Connections {
            target: BrightnessState
            function onBrightnessChanged() {
                if (!brightness.primed) { brightness.primed = true; return; }
                brightness.show();
            }
        }
    }

    OsdPill {
        id: volume
        glyph: Audio.muted     ? ""
             : Audio.volume > 66 ? ""
             : Audio.volume > 0  ? ""
             :                     ""
        percent: Audio.volume
        dimmed:  Audio.muted

        Connections {
            target: Audio
            function onVolumeChanged() { volume.show(); }
            function onMutedChanged()  { volume.show(); }
        }
    }
}
