import Quickshell
import Quickshell.Io
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

Item {
    id: root
    implicitHeight: 20
    implicitWidth:  icon.implicitWidth

    Icon {
        id: icon
        anchors.centerIn: parent
        active: BluetoothState.connectedCount > 0
        text:  BluetoothState.scanning ? "\ue1aa"
             : BluetoothState.powered  ? "\ue1a7"
             :                           "\ue1a9"
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked:    PopupState.toggle(root)
    }

    BarPopup {
        id: popup
        owner: root
        popupWidth: 280
        spacing: 6

        PopupHeader {
            width: parent.width
            title: "Bluetooth"
            on:    BluetoothState.powered
            onToggled: BluetoothState.togglePower(!BluetoothState.powered)
        }

        Column {
            width: parent.width; spacing: 2
            visible: BluetoothState.powered

            Repeater {
                model: BluetoothState.devices
                delegate: PopupRow {
                    required property var modelData
                    width:  parent.width
                    glyph:  modelData.connected ? "" : ""
                    label:  modelData.name
                    active: modelData.connected
                    trailing: modelData.connected ? "" : ""
                    onActivated: BluetoothState.toggleConnect(modelData.mac, modelData.connected)
                }
            }

            PopupEmpty {
                width: parent.width
                visible: BluetoothState.devices.length === 0
                label: "No devices"
            }
        }

        PopupEmpty {
            width: parent.width
            visible: !BluetoothState.powered
            label: "Bluetooth is off"
        }

        PopupAction {
            width: parent.width
            glyph: ""
            label: BluetoothState.scanning ? "Scanning…" : "Scan for 5s"
            enabled: !BluetoothState.scanning && BluetoothState.powered
            onActivated: BluetoothState.scan()
        }
    }
}
