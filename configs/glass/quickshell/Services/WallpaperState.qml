pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    readonly property string statePath: Config.stateDir + "/dotfiles/wallpapers.json"

    // Written by wallpaper.sh as { "<monitor>": { "path": "..." } }
    property var entries: ({})

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object")
                    root.entries = parsed;
            } catch (e) {
                // Keep the previous entries if the file is mid-write
            }
        }
    }

    function entryFor(name) {
        return (name && root.entries[name]) ? root.entries[name] : null;
    }

    function pathFor(name) {
        const e = root.entryFor(name);
        return (e && e.path) ? e.path : "";
    }

    Process { id: applier; running: false }

    function apply(monitor, path) {
        if (!monitor || !path) return;
        applier.command = Config.wallpaperSet.concat([monitor, path]);
        applier.running = true;
    }
}
