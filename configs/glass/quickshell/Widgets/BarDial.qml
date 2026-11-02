import QtQuick
import "../Common"

Row {
    id: root

    property string glyph:     ""
    property string glyphFont: Glass.fontIcon
    property real   glyphSize: 15
    property alias  rings:     dial.rings

    spacing: 4

    Text {
        anchors.verticalCenter: parent.verticalCenter
        font.family: root.glyphFont
        font.pixelSize: root.glyphSize
        font.variableAxes: Glass.iconIdle
        color: Glass.muted
        text:  root.glyph
    }

    Item {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth:  dial.implicitWidth
        implicitHeight: dial.implicitHeight

        Dial {
            id: dial
            anchors.centerIn: parent
            fire: 5.5
        }
    }
}
