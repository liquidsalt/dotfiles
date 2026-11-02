import Quickshell
import Quickshell.Wayland
import QtQuick
import "../Common"
import "../Widgets"

PanelWindow {
    id: root
    visible: false
    color: "transparent"

    property string glyph:   ""
    property int    percent: 0
    property bool   dimmed:  false
    property int    holdFor: 2000

    anchors { bottom: true; left: true; right: true }
    implicitHeight: 88

    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function show() { root.visible = true; hideTimer.restart(); }

    Timer {
        id: hideTimer
        interval: root.holdFor
        onTriggered: root.visible = false
    }

    GlassSurface {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: 210
        height: 40
        radius: 20

        Icon {
            id: icon
            anchors { left: parent.left; leftMargin: 17; verticalCenter: parent.verticalCenter }
            font.pixelSize: 17
            font.variableAxes: root.dimmed ? Glass.iconIdle : Glass.iconActive
            color: root.dimmed ? Glass.muted : Glass.text
            text:  root.glyph
        }

        Label {
            id: value
            anchors { right: parent.right; rightMargin: 17; verticalCenter: parent.verticalCenter }
            width: 32
            horizontalAlignment: Text.AlignRight
            font.features: Glass.tnum
            text:  root.percent + "%"
        }

        Rectangle {
            anchors {
                left: icon.right;  leftMargin: 12
                right: value.left; rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            height: 3
            radius: 1.5
            color: Qt.rgba(1, 1, 1, 0.16)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(root.percent / 100.0, 1.0))
                height: parent.height
                radius: parent.radius
                color: root.dimmed ? Glass.muted : Glass.text
                Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            }
        }
    }
}
