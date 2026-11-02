import QtQuick
import "../Common"

Item {
    id: root

    property alias spacing: line.spacing

    implicitWidth:  line.implicitWidth
    implicitHeight: line.implicitHeight

    property string glyph:  ""
    property string value:  ""
    property bool   alert:  false
    property bool   filled: false
    property color  tint:   Glass.muted

    Row {
        id: line
        anchors.centerIn: parent
        spacing: 4

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 15
            active: root.filled
            color: root.alert ? Glass.critical : root.tint
            text:  root.glyph
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            font.features: Glass.tnum
            color: root.alert ? Glass.critical : Glass.muted
            text:  root.value
        }
    }
}
