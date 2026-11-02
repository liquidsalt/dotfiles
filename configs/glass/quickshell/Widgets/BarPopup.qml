import Quickshell
import QtQuick
import "../Common"
import "../Services"

PopupWindow {
    id: root

    required property Item owner
    property string title:      ""
    property int    popupWidth: 300
    property int    margins:    10
    property alias  spacing:    col.spacing
    default property alias content: col.data

    visible: PopupState.owner === root.owner
    grabFocus: true
    onClosed: if (PopupState.owner === root.owner) PopupState.close()
    color: "transparent"
    implicitWidth:  root.popupWidth
    implicitHeight: shell.implicitHeight

    anchor.item: root.owner
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10

    GlassSurface {
        id: shell
        anchors.fill: parent
        strong: true
        implicitHeight: col.implicitHeight + root.margins * 2

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.margins }
            spacing: 4

            Label {
                visible: root.title !== ""
                height: 30
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: -0.13
                color: Glass.text
                text:  root.title
            }
        }
    }
}
