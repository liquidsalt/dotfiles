import QtQuick
import "../Common"

Item {
    id: root
    height: 30

    property string title: ""
    property bool   on:    false
    signal toggled()

    Label {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.letterSpacing: -0.13
        color: Glass.text
        text:  root.title
    }

    Rectangle {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 34; height: 19; radius: 9.5
        color: root.on ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.07)
        border.width: 1
        border.color: Glass.stroke

        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
            width: 13; height: 13; radius: 6.5
            y: 3
            x: root.on ? parent.width - width - 3 : 3
            color: root.on ? Glass.text : Glass.faint
            Behavior on x     { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 160 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
}
