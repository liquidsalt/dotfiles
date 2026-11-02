import Quickshell
import Quickshell.Wayland
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window
        required property ShellScreen modelData
        screen: modelData

        anchors { top: true; left: true; right: true }
        implicitHeight: Glass.barZone
        color: "transparent"

        WlrLayershell.namespace: "quickshell:bar"
        WlrLayershell.layer: WlrLayer.Top

        GlassSurface {
            id: panel

            anchors {
                left:       parent.left
                right:      parent.right
                top:        parent.top
                leftMargin:  Glass.barMargin
                rightMargin: Glass.barMargin
                topMargin:   Glass.barTop
            }
            height: Glass.barHeight
            radius: Glass.barRadius

            Row {
                anchors {
                    left: parent.left
                    leftMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                spacing: 13

                BarWorkspaces {
                    screenName: window.modelData.name
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 1; height: 13
                    color: Qt.rgba(1, 1, 1, 0.13)
                    anchors.verticalCenter: parent.verticalCenter
                }

                BarTray { }
                BarDisplay { }
            }

            BarClock { anchors.centerIn: parent }

            Row {
                anchors {
                    right: parent.right
                    rightMargin: 16
                    verticalCenter: parent.verticalCenter
                }
                spacing: 13

                BarStat {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph:  Audio.muted ? "\ue04f" : "\ue050"
                    value:  Audio.volume + "%"
                    filled: !Audio.muted
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.MiddleButton) Audio.toggleMute();
                            else Quickshell.execDetached(Config.audioMixer);
                        }
                        onWheel: (wheel) => Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0 ? 5 : -5))
                    }
                }

                BarLoads { anchors.verticalCenter: parent.verticalCenter }
                BarPower { anchors.verticalCenter: parent.verticalCenter }

                Rectangle {
                    width: 1; height: 13
                    color: Qt.rgba(1, 1, 1, 0.13)
                    anchors.verticalCenter: parent.verticalCenter
                }

                BarWifi { }
                BarBluetooth { }
            }
        }
    }
}
