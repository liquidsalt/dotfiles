import QtQuick
import "../Common"

Item {
    id: root

    property int   value:    0
    property bool  charging: false
    property color fill:     Glass.text

    implicitWidth:  22
    implicitHeight: 11

    Rectangle {
        id: body
        width:  root.width - 3
        height: root.height
        radius: 3
        color:  "transparent"
        border.width: 1
        border.color: Glass.muted

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 2 }
            width:  (body.width - 4) * Math.max(0, Math.min(100, root.value)) / 100
            radius: 1.5
            color:  root.fill
            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Icon {
            anchors.centerIn: parent
            visible: root.charging
            font.pixelSize: 11
            font.variableAxes: Glass.iconActive
            color: Glass.text
            style: Text.Outline
            styleColor: Glass.ink
            text: ""  // bolt
        }
    }

    Rectangle {
        anchors { left: body.right; leftMargin: 1; verticalCenter: body.verticalCenter }
        width: 2; height: 5; radius: 1
        color: Glass.muted
    }
}
