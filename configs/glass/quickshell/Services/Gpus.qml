pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    // [{ name, vendor, integrated, awake, load, temp, limit, memUsed, memTotal, clock, maxClock }]
    // Primary first, an awake discrete card before the integrated one
    readonly property var list: {
        var out = [];
        for (var k in root.cards) if (root.cards[k].vendor) out.push(root.cards[k]);
        out.sort((a, b) => root._rank(a) - root._rank(b));
        return out;
    }

    function _rank(g) { return g.integrated ? 1 : g.awake ? 0 : 2; }

    property var cards: ({})

    function _set(card, info) {
        var next = ({});
        for (var k in root.cards) next[k] = root.cards[k];
        next[card] = info;
        root.cards = next;
    }

    SysDir { id: drm; path: "/sys/class/drm" }

    Instantiator {
        id: instances
        model: drm.names.filter(n => /^card\d+$/.test(n))

        delegate: Scope {
            id: card

            readonly property string base: "/sys/class/drm/" + modelData

            property string vendor:     ""
            property bool   integrated: false
            property bool   awake:      true
            property string smiName:    ""
            property int    load:       0
            property int    temp:       0
            property int    limit:      0
            property int    memUsed:    0  // MiB
            property int    memTotal:   0
            property int    clock:      0  // MHz
            property int    maxClock:   0

            readonly property bool isIntel:  vendor === "0x8086"
            readonly property bool isNvidia: vendor === "0x10de"
            readonly property bool isAmd:    vendor === "0x1002"

            readonly property string name: isNvidia ? smiName : isIntel ? "Intel graphics" : isAmd ? "AMD graphics" : ""

            function publish() {
                root._set(modelData, {
                    name: card.name, vendor: card.vendor, integrated: card.integrated,
                    awake: card.awake, load: card.load,
                    temp:  card.isIntel ? SystemStats.cpuTemp : card.temp,
                    limit: card.isIntel ? SystemStats.cpuTempMax : card.limit,
                    memUsed: card.memUsed, memTotal: card.memTotal,
                    clock: card.clock, maxClock: card.maxClock
                });
            }

            function poll() {
                runtime.reload();
                if (card.isIntel) { actFreq.reload(); }
                if (card.isAmd)   { busy.reload(); vramUsed.reload(); }
                card.publish();
            }

            FileView {
                path: card.base + "/device/vendor"
                onLoaded: card.vendor = text().trim()
            }

            // Integrated GPUs sit on PCI bus 00
            FileView {
                path: card.base + "/device/uevent"
                onLoaded: {
                    var m = /PCI_SLOT_NAME=[0-9a-f]+:([0-9a-f]+):/.exec(text());
                    card.integrated = !!m && m[1] === "00";
                }
            }

            FileView {
                id: runtime
                path: card.base + "/device/power/runtime_status"
                printErrors: false
                onLoaded: {
                    card.awake = text().trim() !== "suspended";
                    if (!card.isNvidia) return;
                    if (!card.awake) { card.load = 0; card.clock = 0; card.publish(); }
                    else if (!smi.running) smi.running = true;  // nvidia-smi would wake a sleeping card
                }
            }

            FileView {
                id: actFreq
                path: card.isIntel ? card.base + "/gt_act_freq_mhz" : ""
                printErrors: false
                onLoaded: {
                    card.clock = parseInt(text().trim(), 10) || 0;
                    if (card.maxClock > 0) card.load = Math.round(card.clock / card.maxClock * 100);
                }
            }

            FileView {
                path: card.isIntel ? card.base + "/gt_RP0_freq_mhz" : ""
                printErrors: false
                onLoaded: card.maxClock = parseInt(text().trim(), 10) || 0
            }

            FileView {
                id: busy
                path: card.isAmd ? card.base + "/device/gpu_busy_percent" : ""
                printErrors: false
                onLoaded: card.load = parseInt(text().trim(), 10) || 0
            }

            FileView {
                id: vramUsed
                path: card.isAmd ? card.base + "/device/mem_info_vram_used" : ""
                printErrors: false
                onLoaded: card.memUsed = Math.round(parseInt(text().trim(), 10) / 1048576) || 0
            }

            FileView {
                path: card.isAmd ? card.base + "/device/mem_info_vram_total" : ""
                printErrors: false
                onLoaded: card.memTotal = Math.round(parseInt(text().trim(), 10) / 1048576) || 0
            }

            Process {
                id: smi
                command: ["nvidia-smi",
                          "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,temperature.gpu.tlimit,clocks.current.graphics,name",
                          "--format=csv,noheader,nounits"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        var f = text.trim().split(",").map(s => s.trim());
                        if (f.length < 7) return;
                        card.load     = parseInt(f[0], 10) || 0;
                        card.memUsed  = parseInt(f[1], 10) || 0;
                        card.memTotal = parseInt(f[2], 10) || 0;
                        card.temp     = parseInt(f[3], 10) || 0;
                        card.limit    = card.temp + (parseInt(f[4], 10) || 0);  // tlimit is the headroom left
                        card.clock    = parseInt(f[5], 10) || 0;
                        card.smiName  = f.slice(6).join(",");
                        card.publish();
                    }
                }
            }
        }
    }

    Timer {
        interval: 2000; running: true; triggeredOnStart: true; repeat: true
        onTriggered: {
            for (var i = 0; i < instances.count; i++) {
                var c = instances.objectAt(i);
                if (c) c.poll();
            }
        }
    }
}
