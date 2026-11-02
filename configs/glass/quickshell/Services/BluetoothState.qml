pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool powered: adapter ? adapter.enabled : false
    readonly property bool scanning: adapter ? adapter.discovering : false

    readonly property var devices: {
        var devs = Bluetooth.devices.values.map(function(d) {
            return { connected: d.connected, mac: d.address, name: d.name, device: d };
        });
        devs.sort(function(a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
        });
        return devs;
    }

    readonly property int connectedCount:
        Bluetooth.devices.values.filter(function(d) { return d.connected; }).length

    readonly property int scanSeconds: 5

    function togglePower(state) { if (root.adapter) root.adapter.enabled = state; }

    function toggleConnect(mac, connected) {
        var d = Bluetooth.devices.values.find(d => d.address === mac);
        if (!d) return;
        if (connected) d.disconnect();
        else d.connect();
    }

    function scan() {
        if (!root.adapter || root.scanning) return;
        root.adapter.discovering = true;
        scanStop.restart();
    }

    Timer {
        id: scanStop
        interval: root.scanSeconds * 1000
        onTriggered: if (root.adapter) root.adapter.discovering = false
    }
}
