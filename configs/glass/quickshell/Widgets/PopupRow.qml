import QtQuick
import "../Common"

Rectangle {
    id: root
    height: Glass.rowHeight - 6
    radius: Glass.rowRadius

    property string glyph:    ""
    property string track:    ""  // faint full glyph behind glyph, like a signal meter
    property string label:    ""
    property string trailing: ""
    property bool   active:   false
    signal activated()

    property string action: ""  // glyph for an extra button on the right
    signal actionTriggered()

    color: mouse.containsMouse || actionMouse.containsMouse ? Glass.hover : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    // Before the Row so the action button's MouseArea stays on top
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.activated()
    }

    Row {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 10

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width:  Math.max(rowTrack.implicitWidth, rowGlyph.implicitWidth)
            height: rowGlyph.implicitHeight

            Icon {
                id: rowTrack
                anchors.centerIn: parent
                visible: root.track !== ""
                color: Glass.faint
                text:  root.track
            }

            Icon {
                id: rowGlyph
                anchors.centerIn: parent
                active: root.active
                text:  root.glyph
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 66 - (root.action !== "" ? 34 : 0)
            font.pixelSize: 13
            font.letterSpacing: -0.1
            color: root.active ? Glass.text : Glass.muted
            text:  root.label
            elide: Text.ElideRight
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.action !== ""
            width: 24; height: 24
            radius: 8
            color: actionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Icon {
                anchors.centerIn: parent
                font.pixelSize: 15
                active: actionMouse.containsMouse
                text:  root.action
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.action !== ""
                cursorShape: Qt.PointingHandCursor
                onClicked:   root.actionTriggered()
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.trailing !== ""
            font.pixelSize: 15
            color: root.active ? Glass.text : Glass.faint
            text:  root.trailing
        }
    }
}
