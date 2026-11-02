pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string homeDir:    Quickshell.env("HOME")
    readonly property string configDir:  Quickshell.env("XDG_CONFIG_HOME") || homeDir + "/.config"
    readonly property string stateDir:   Quickshell.env("XDG_STATE_HOME") || homeDir + "/.local/state"
    readonly property string dataDir:    Quickshell.env("XDG_DATA_HOME") || homeDir + "/.local/share"
    readonly property string scriptsDir: dataDir + "/dotfiles/scripts"

    readonly property string monitorConf:        configDir + "/dotfiles/monitor-conf.json"
    readonly property string monitorState:       stateDir + "/dotfiles/monitors.json"
    readonly property string wallpapers:         dataDir + "/dotfiles/wallpapers/horizontal"
    readonly property string wallpapersVertical: dataDir + "/dotfiles/wallpapers/vertical"

    readonly property var wallpaperSet:   [scriptsDir + "/wallpaper", "set"]
    readonly property var audioMixer:     ["pavucontrol"]

    readonly property var powerSources: [
        { name: "headset", label: "Headset", glyph: "\ue310", argv: [scriptsDir + "/nari-essential-battery"] }  // headphones
    ]

    function wallpaperRootFor(orientation) {
        return orientation === "Vertical" ? root.wallpapersVertical : root.wallpapers;
    }

    // Five per output by index, 0 gets 1-5, 1 gets 6-10
    function workspacesFor(output) {
        var i = root.monitorIndices[output];
        if (i === undefined) return [];
        var out = [];
        for (var n = 1; n <= 5; n++) out.push(i * 5 + n);
        return out;
    }

    // { w, h, r } or null for no ceiling
    function monitorMax(output) {
        var v = root.monitorCeilings[output];
        return v === undefined ? null : v;
    }

    property var monitorCeilings: ({})  // { "<port>": { w, h, r } }
    property var monitorIndices:  ({})  // { "<port>": index }

    FileView {
        id: monitorConfFile
        path: root.monitorConf
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: {
        var screens = [];
        try {
            var conf = JSON.parse(monitorConfFile.text());
            for (var group in conf)
                for (var name in conf[group]) screens.push(conf[group][name]);
        } catch (e) { return; }
        root.monitorCeilings = root._ceilings(screens);
        root.monitorIndices  = root._indices(screens);
    }

    function _indices(screens) {
        var out = ({});
        for (var i = 0; i < screens.length; i++) {
            var s = screens[i];
            if (s.port && s.index !== undefined) out[s.port] = s.index;
        }
        return out;
    }

    function _ceilings(screens) {
        var out = ({});
        for (var i = 0; i < screens.length; i++) {
            var s = screens[i];
            if (!s || !s["port"]) continue;

            var res  = s["max-resolution"];
            var rate = s["max-refresh-rate"];
            if (res === undefined) continue;

            var m = /^(\d+)\s*x\s*(\d+)$/.exec(String(res).trim());
            if (!m) continue;

            var entry = {
                w: parseInt(m[1], 10),
                h: parseInt(m[2], 10),
                r: (rate === undefined || isNaN(parseFloat(rate)))
                    ? 1e6 : parseFloat(rate)  // no rate means no rate ceiling
            };

            var port = s["port"];
            var prev = out[port];
            if (prev === undefined
                || entry.w * entry.h > prev.w * prev.h
                || (entry.w * entry.h === prev.w * prev.h && entry.r > prev.r))
                out[port] = entry;
        }
        return out;
    }
}
