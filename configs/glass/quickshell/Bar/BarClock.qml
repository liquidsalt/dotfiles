import QtQuick
import "../Common"
import "../Widgets"

Row {
    id: root
    spacing: 9

    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        font.pixelSize: 13
        font.weight: Font.Medium
        font.letterSpacing: -0.13
        font.features: Glass.tnum
        color: Glass.text
        text:  Qt.formatDateTime(root.now, "HH:mm")
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text:  Qt.formatDateTime(root.now, "ddd dd MMM")
    }
}
