pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"

Singleton {
    id: root

    property int    capacity:   0
    property string status:     "Unknown"
    property real   energyNow:  0  // Wh
    property real   energyFull: 0
    property real   power:      0  // W

    readonly property bool present:  root.base !== ""
    readonly property bool charging: root.status === "Charging"

    // Hours until empty, or until full while charging, 0 when unknown
    readonly property real hoursLeft: {
        if (root.power <= 0) return 0;
        if (root.charging) return (root.energyFull - root.energyNow) / root.power;
        if (root.status === "Discharging") return root.energyNow / root.power;
        return 0;
    }

    property string base: ""

    SysDir { id: supplies; path: "/sys/class/power_supply" }

    // The laptop's own battery is type Battery without scope Device, which marks peripherals
    Instantiator {
        model: supplies.names
        delegate: Scope {
            id: supply
            readonly property string dir: "/sys/class/power_supply/" + modelData
            property bool battery: false
            property bool device:  false

            onBatteryChanged: supply.claim()
            onDeviceChanged:  supply.claim()

            function claim() {
                if (supply.battery && !supply.device && root.base === "") root.base = supply.dir;
                if (supply.device && root.base === supply.dir) root.base = "";
            }

            FileView {
                path: supply.dir + "/type"
                onLoaded: supply.battery = text().trim() === "Battery"
            }

            FileView {
                path: supply.dir + "/scope"
                printErrors: false
                onLoaded: supply.device = text().trim() === "Device"
            }
        }
    }

    function _num(view) { return parseInt(view.text().trim(), 10) || 0; }

    FileView { id: cap;     path: root.base ? root.base + "/capacity" : "";    onLoaded: root.capacity = root._num(cap) }
    FileView { id: stat;    path: root.base ? root.base + "/status" : "";      onLoaded: root.status = stat.text().trim() }
    FileView { id: eNow;    path: root.base ? root.base + "/energy_now" : "";  printErrors: false; onLoaded: root.energyNow = root._num(eNow) / 1e6 }
    FileView { id: eFull;   path: root.base ? root.base + "/energy_full" : ""; printErrors: false; onLoaded: root.energyFull = root._num(eFull) / 1e6 }
    FileView { id: pNow;    path: root.base ? root.base + "/power_now" : "";   printErrors: false; onLoaded: root.power = root._num(pNow) / 1e6 }

    function refresh() {
        if (!root.present) return;
        cap.reload(); stat.reload(); eNow.reload(); eFull.reload(); pNow.reload();
    }

    Timer {
        interval: 15000
        running: true
        triggeredOnStart: true
        repeat: true
        onTriggered: root.refresh()
    }
}
