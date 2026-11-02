import Quickshell
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

Item {
    id: root

    implicitWidth:  line.implicitWidth
    implicitHeight: 20

    readonly property bool laptopLow: LaptopBattery.capacity <= 20 && !LaptopBattery.charging

    function duration(hours) {
        var m = Math.round(hours * 60);
        return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " min" : m + " min";
    }

    readonly property var laptopDetail: {
        var first = LaptopBattery.status;
        if (LaptopBattery.hoursLeft > 0)
            first += "   ·   " + root.duration(LaptopBattery.hoursLeft)
                   + (LaptopBattery.charging ? " to full" : " left");
        var second = LaptopBattery.energyNow.toFixed(1) + " / " + LaptopBattery.energyFull.toFixed(1) + " Wh";
        if (LaptopBattery.power > 0) second += "   ·   " + LaptopBattery.power.toFixed(1) + " W";
        return [first, second];
    }

    function refreshAll() {
        LaptopBattery.refresh();
        PowerSources.refresh();
    }

    Row {
        id: line
        anchors.centerIn: parent
        spacing: 10

        BatteryIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible:  LaptopBattery.present
            value:    LaptopBattery.capacity
            charging: LaptopBattery.charging
            fill:     root.laptopLow ? Glass.critical : PowerProfile.tint
        }

        Repeater {
            model: PowerSources.list.filter(s => s.present)

            delegate: Row {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                    text:  modelData.glyph
                }

                BatteryIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    value:    modelData.value
                    charging: modelData.caption === "charging"
                    fill:     modelData.value <= 20 ? Glass.critical : Glass.text
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            var opening = PopupState.owner !== root;
            PopupState.toggle(root);
            if (opening) root.refreshAll();
        }
    }

    BarPopup {
        id: popup
        owner: root
        title: "Power"
        popupWidth: 300
        spacing: 4

        PopupGauge {
            width: parent.width
            visible: LaptopBattery.present
            glyph:  "\uf304"  // battery_android_full
            title:  "Laptop"
            value:  LaptopBattery.capacity
            tint:   root.laptopLow ? Glass.critical : PowerProfile.tint
            detail: root.laptopDetail
        }

        Repeater {
            model: PowerSources.list
            delegate: PopupGauge {
                required property var modelData
                width: parent.width
                glyph:  modelData.glyph
                title:  modelData.label
                value:  modelData.value
                tint:   modelData.value <= 20 ? Glass.critical : Glass.text
                detail: [modelData.present ? modelData.caption : "not connected"]
            }
        }

        Item { width: 1; height: 4 }

        Rectangle {
            width:  parent.width
            height: 32
            radius: 11
            color:  Qt.rgba(1, 1, 1, 0.05)

            Row {
                id: cells
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: PowerProfile.profiles

                    delegate: Rectangle {
                        required property var modelData

                        readonly property bool on: PowerProfile.current === modelData.id

                        width:  (cells.width - 6) / 3
                        height: cells.height
                        radius: 8
                        color: on ? Qt.rgba(PowerProfile.tint.r, PowerProfile.tint.g,
                                            PowerProfile.tint.b, 0.24)
                             : hover.containsMouse ? Glass.hover
                             :                       "transparent"

                        Behavior on color { ColorAnimation { duration: 140 } }

                        Label {
                            anchors.centerIn: parent
                            font.pixelSize: 11
                            color: parent.on ? Glass.text : Glass.muted
                            text:  modelData.label
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked:    PowerProfile.set(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
