pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    readonly property var configured: Config.powerSources

    property var readings: ({})  // { name: { percent, caption, present } }

    readonly property var list: {
        var out = [];
        for (var i = 0; i < root.configured.length; i++) {
            var src = root.configured[i];
            var r = root.readings[src.name];
            out.push({
                label:   src.label,
                glyph:   src.glyph,
                present: r !== undefined && r.present === true,
                value:   r !== undefined ? r.percent : 0,
                caption: r !== undefined ? r.caption : ""
            });
        }
        return out;
    }

    function prev(name) { return root.readings[name] ? root.readings[name].percent : 0; }

    function refresh() {
        for (var i = 0; i < repeater.count; i++) {
            var it = repeater.itemAt(i);
            if (it) it.poll();
        }
    }

    Repeater {
        id: repeater
        model: root.configured

        delegate: Item {
            required property var modelData

            function poll() { if (!proc.running) proc.running = true; }

            Process {
                id: proc
                command: modelData.argv
                running: false

                stdout: StdioCollector {
                    onStreamFinished: {
                        var line = text.split("\n")[0].trim();
                        // "85% discharging", or just "charging" / "full" while on the charger
                        var m = /^(?:(\d+)%?\s*)?(charging|discharging|full)$/.exec(line);
                        var next = ({});
                        // Copy, QML doesn't notice a var changed in place
                        for (var k in root.readings) next[k] = root.readings[k];
                        next[modelData.name] = {
                            percent: m ? (m[1] ? parseInt(m[1], 10) : m[2] === "full" ? 100 : root.prev(modelData.name)) : 0,
                            caption: m ? m[2].trim() : "",
                            present: !!m
                        };
                        root.readings = next;
                    }
                }

                // Non-zero exit means the device is off or gone
                onExited: exitCode => {
                    if (exitCode === 0) return;
                    var next = ({});
                    for (var k in root.readings) next[k] = root.readings[k];
                    next[modelData.name] = { percent: 0, caption: "", present: false };
                    root.readings = next;
                }
            }

            Timer {
                interval: 120000  // two minutes, each poll is a radio round trip
                running: true
                triggeredOnStart: true
                repeat: true
                onTriggered: proc.running = true
            }
        }
    }
}
