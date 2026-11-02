pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "../Common"

Singleton {
    id: root

    // [{ name, current, rate, modes: [{ mode, label, rate, active }] }]
    readonly property var outputs: root.parse(Hyprland.monitors.values.map(m => m.lastIpcObject))

    readonly property int minWidth: 1280

    // Modes with another aspect ratio would letterbox or stretch
    readonly property real aspectTolerance: 0.02

    function refresh() { Hyprland.refreshMonitors(); }

    function parseMode(s) {
        var m = /^(\d+)x(\d+)@([\d.]+)Hz?$/.exec(s.trim());
        if (!m)
            return null;
        return { w: parseInt(m[1]), h: parseInt(m[2]), r: Math.round(parseFloat(m[3])) };
    }

    function parse(mons) {
        var out = [];
        for (var i = 0; i < mons.length; i++) {
            var mon = mons[i];
            if (!mon || !mon.name) continue;
            var cap = Config.monitorMax(mon.name);
            var list = mon.availableModes || [];

            var aspect = cap ? (cap.w / cap.h) : (mon.width / mon.height);

            // One entry per resolution at its fastest refresh
            var best = ({});
            for (var j = 0; j < list.length; j++) {
                var mode = root.parseMode(list[j]);
                if (!mode || mode.w < root.minWidth)
                    continue;
                if (cap && (mode.w > cap.w || mode.h > cap.h || mode.r > cap.r))
                    continue;
                if (Math.abs(mode.w / mode.h - aspect) > root.aspectTolerance)
                    continue;
                var key = mode.w + "x" + mode.h;
                if (best[key] === undefined || mode.r > best[key])
                    best[key] = mode.r;
            }

            var dims = [];
            for (var k in best)
                dims.push({ w: parseInt(k.split("x")[0]),
                            h: parseInt(k.split("x")[1]),
                            r: best[k] });
            dims.sort(function (a, b) { return (b.w - a.w) || (b.h - a.h); });

            var rows = [];
            for (var d = 0; d < dims.length; d++) {
                rows.push({
                    mode:  dims[d].w + "x" + dims[d].h + "@" + dims[d].r,
                    label: dims[d].w + " × " + dims[d].h,
                    rate:  dims[d].r + " Hz",
                    active: dims[d].w === mon.width && dims[d].h === mon.height  // refresh rate ignored
                });
            }

            out.push({
                name:    mon.name,
                current: mon.width + " × " + mon.height,
                rate:    Math.round(mon.refreshRate) + " Hz",
                modes:   rows
            });
        }
        return out;
    }

    function modesFor(name) {
        for (var i = 0; i < root.outputs.length; i++)
            if (root.outputs[i].name === name)
                return root.outputs[i].modes;
        return [];
    }

    // monitors.lua reads the same file, so a reload is enough to apply it
    function save(name, change) {
        stateFile.reload();
        var state = ({});
        try { state = JSON.parse(stateFile.text()); } catch (e) {}
        state[name] = Object.assign(state[name] || {}, change);
        writer.command = ["sh", "-c", 'mkdir -p "${1%/*}" && printf "%s\\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1" && hyprctl reload',
                          "sh", Config.monitorState, JSON.stringify(state, null, 2)];
        writer.running = true;
        settle.restart();
    }

    // mode as 2560x1440@144
    function apply(name, mode) {
        var m = /^(\d+x\d+)@([\d.]+)$/.exec(mode);
        if (m) root.save(name, { resolution: m[1], refresh: parseFloat(m[2]) });
    }

    // Between upright and sideways, like the keybind in monitors.lua
    function rotate(name) {
        var mon = Hyprland.monitors.values.find(m => m.name === name);
        var current = mon && mon.lastIpcObject ? mon.lastIpcObject.transform : 0;
        root.save(name, { rotation: current === 0 ? 3 : 0 });
    }

    FileView { id: stateFile; path: Config.monitorState; blockLoading: true; printErrors: false }
    Process  { id: writer; running: false }

    Timer {
        id: settle
        interval: 2500
        repeat: false
        onTriggered: root.refresh()
    }
}
