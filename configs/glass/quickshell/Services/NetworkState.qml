pragma Singleton
import Quickshell
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    readonly property var wifiDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i];
        return null;
    }

    readonly property var wiredDevice: {
        var devs = Networking.devices.values;
        for (var i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wired) return devs[i];
        return null;
    }

    readonly property bool isEthernet: wiredDevice ? wiredDevice.connected : false
    readonly property bool connected:  isEthernet || (wifiDevice ? wifiDevice.connected : false)

    readonly property bool wifiEnabled: Networking.wifiEnabled

    readonly property var networks: {
        if (!wifiDevice) return [];
        var nets = wifiDevice.networks.values.map(function(n) {
            return {
                inUse:  n.connected,
                ssid:   n.name,
                signal: Math.round(n.signalStrength * 100),
                sec:    root.securityLabel(n.security),
                known:  n.known,
                network: n
            };
        }).filter(function(n) { return n.ssid.length > 0; });
        nets.sort(function(a, b) {
            if (a.inUse !== b.inUse) return a.inUse ? -1 : 1;
            return b.signal - a.signal;
        });
        return nets;
    }

    readonly property var savedConnections:
        root.networks.filter(function(n) { return n.known; })
                     .map(function(n) { return n.ssid; })

    function securityLabel(sec) {
        if (sec === WifiSecurityType.Open || sec === WifiSecurityType.Unknown) return "--";
        return WifiSecurityType.toString(sec);
    }

    function refreshNetworks() {
        if (wifiDevice) wifiDevice.scannerEnabled = true;
    }

    function stopScanning() {
        if (wifiDevice) wifiDevice.scannerEnabled = false;
    }

    function _find(ssid) {
        for (var i = 0; i < root.networks.length; i++)
            if (root.networks[i].ssid === ssid) return root.networks[i].network;
        return null;
    }

    function toggle(state) { Networking.wifiEnabled = state; }

    function connect(ssid, psk) {
        var n = root._find(ssid);
        if (!n) return;
        if (psk) n.connectWithPsk(psk);
        else n.connect();
    }

    function disconnect() { if (root.wifiDevice) root.wifiDevice.disconnect(); }
}
