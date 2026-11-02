import QtQuick
import "../Common"

Item {
    id: root
    height: visible ? 30 : 0

    property string label: ""

    Label {
        anchors.centerIn: parent
        color: Glass.faint
        text:  root.label
    }
}
