import QtQuick
import "../Common"

Rectangle {
    id: root
    height: 32
    radius: Glass.rowRadius

    property string glyph:   ""
    property string label:   ""
    property bool   enabled: true
    signal activated()

    color: mouse.containsMouse && root.enabled ? Glass.hover : Qt.rgba(1, 1, 1, 0.04)
    Behavior on color { ColorAnimation { duration: 120 } }
    opacity: root.enabled ? 1.0 : 0.45

    Row {
        anchors.centerIn: parent
        spacing: 8

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 15
            text:  root.glyph
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text:  root.label
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled:      root.enabled
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.activated()
    }
}
