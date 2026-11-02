pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0

    property string cpuModel:  ""
    property int    cpuThreads: 0
    property string loadAvg:   ""
    property int    cpuTemp:    0
    property int    cpuTempMax: 95  // replaced by the sensor's own limit when it has one

    property real memUsedGiB:   0
    property real memAvailGiB:  0
    property real memCacheGiB:  0
    property real memTotalGiB:  0
    property real swapUsedGiB:  0
    property real swapTotalGiB: 0

    property real lastTotal: 0
    property real lastIdle:  0

    FileView {
        id: statFile
        path: "/proc/stat"
        watchChanges: false
        onLoaded: {
            var line = text().split("\n")[0];
            var f = line.trim().split(/\s+/);
            var user    = parseFloat(f[1]);
            var nice    = parseFloat(f[2]);
            var sys     = parseFloat(f[3]);
            var idle    = parseFloat(f[4]);
            var iowait  = parseFloat(f[5] || 0);
            var irq     = parseFloat(f[6] || 0);
            var softirq = parseFloat(f[7] || 0);
            var total   = user + nice + sys + idle + iowait + irq + softirq;
            var idleAll = idle + iowait;
            if (root.lastTotal > 0) {
                var dt = total - root.lastTotal;
                var di = idleAll - root.lastIdle;
                if (dt > 0) root.cpuPercent = Math.round((1 - di / dt) * 100);
            }
            root.lastTotal = total;
            root.lastIdle  = idleAll;
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        watchChanges: false
        onLoaded: {
            var t = text();
            function kb(key) {
                var m = new RegExp(key + ":\\s+(\\d+)").exec(t);
                return m ? parseInt(m[1], 10) : 0;
            }
            var total = kb("MemTotal");
            var avail = kb("MemAvailable");
            if (total && avail) {
                root.memPercent  = Math.round((1 - avail / total) * 100);
                root.memTotalGiB = total / 1048576;
                root.memUsedGiB  = (total - avail) / 1048576;
                root.memAvailGiB = avail / 1048576;
            }
            root.memCacheGiB = (kb("Cached") + kb("Buffers") + kb("SReclaimable")) / 1048576;
            var swTotal = kb("SwapTotal");
            var swFree  = kb("SwapFree");
            root.swapTotalGiB = swTotal / 1048576;
            root.swapUsedGiB  = (swTotal - swFree) / 1048576;
        }
    }

    FileView {
        path: "/proc/cpuinfo"
        watchChanges: false
        onLoaded: {
            var m = /model name\s*:\s*(.+)/.exec(text());
            root.cpuThreads = (text().match(/^processor\s*:/gm) || []).length;
            if (m) root.cpuModel = m[1].replace(/\((R|TM)\)/g, "")
                                       .replace(/\s+/g, " ").trim();
        }
    }

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        watchChanges: false
        onLoaded: {
            var f = text().trim().split(/\s+/);
            if (f.length >= 3) root.loadAvg = f[0] + "  " + f[1] + "  " + f[2];
        }
    }

    readonly property var cpuSensors: ["coretemp", "k10temp", "zenpower"]
    property string cpuHwmon: ""

    SysDir { id: hwmon; path: "/sys/class/hwmon" }

    Instantiator {
        model: hwmon.names
        delegate: FileView {
            path: "/sys/class/hwmon/" + modelData + "/name"
            onLoaded: if (root.cpuSensors.indexOf(text().trim()) >= 0)
                root.cpuHwmon = "/sys/class/hwmon/" + modelData
        }
    }

    FileView {
        id: tempFile
        path: root.cpuHwmon ? root.cpuHwmon + "/temp1_input" : ""
        printErrors: false
        onLoaded: {
            var n = parseInt(text().trim(), 10);
            if (!isNaN(n)) root.cpuTemp = Math.round(n / 1000);
        }
    }

    FileView {
        path: root.cpuHwmon ? root.cpuHwmon + "/temp1_max" : ""
        printErrors: false
        onLoaded: {
            var n = parseInt(text().trim(), 10);
            if (n > 0) root.cpuTempMax = Math.round(n / 1000);
        }
    }

    Timer {
        interval: 2000; running: true; triggeredOnStart: true; repeat: true
        onTriggered: {
            statFile.reload(); memFile.reload();
            loadFile.reload(); tempFile.reload();
        }
    }
}
