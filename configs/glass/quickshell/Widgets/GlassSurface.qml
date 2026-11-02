import QtQuick
import "../Common"

Rectangle {
    id: root

    property bool strong: false

    color:        root.strong ? Glass.panelStrong : Glass.panel
    radius:       Glass.popupRadius
    border.width: 1
    border.color: Glass.stroke
    antialiasing: true
}
