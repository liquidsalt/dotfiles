import Quickshell
import Quickshell.Io
import QtQuick
import "../Common"
import "../Services"
import "../Widgets"

Item {
    id: root
    implicitHeight: 20
    implicitWidth:  chip.implicitWidth

    property string expanded: ""  // output name

    Icon {
        id: chip
        anchors.centerIn: parent
        font.pixelSize: 17
        active: PopupState.owner === root
        text: "\ue85b"  // aspect_ratio
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var opening = PopupState.owner !== root;
            PopupState.toggle(root);
            if (opening) {
                root.expanded = "";
                MonitorModes.refresh();
            }
        }
    }

    BarPopup {
        id: popup
        owner: root
        title: "Display"
        popupWidth: 308
        spacing: 6
        onVisibleChanged: if (!visible) { root.expanded = ""; }

        Column {
            width: parent.width
            spacing: 2

            Repeater {
                model: MonitorModes.outputs

                delegate: Column {
                    id: output
                    required property var modelData
                    width: parent.width
                    spacing: 2

                    readonly property bool open:
                        root.expanded === output.modelData.name

                    PopupRow {
                        width: parent.width
                        glyph:  "\uef5b"  // monitor
                        label:  output.modelData.name + "  ·  " + output.modelData.current
                        active: output.open
                        trailing: output.open ? "\ue5cf" : "\ue409"  // expand_more, chevron_right
                        onActivated: root.expanded =
                            output.open ? "" : output.modelData.name

                        action: "\ue863"  // autorenew
                        onActionTriggered: MonitorModes.rotate(output.modelData.name)
                    }

                    Column {
                        visible: output.open
                        width: parent.width - 16
                        x: 16
                        spacing: 2
                        bottomPadding: output.open ? 4 : 0

                        Repeater {
                            model: MonitorModes.modesFor(output.modelData.name)

                            delegate: PopupRow {
                                required property var modelData
                                width: parent.width
                                glyph:  "\ue85b"  // aspect_ratio
                                label:  modelData.label + "  ·  " + modelData.rate
                                active: modelData.active
                                trailing: modelData.active ? "\ue5ca" : ""  // check
                                onActivated: {
                                    if (!modelData.active)
                                        MonitorModes.apply(output.modelData.name,
                                                           modelData.mode);
                                    PopupState.close();
                                    root.expanded = "";
                                }
                            }
                        }
                    }
                }
            }

            PopupEmpty {
                width: parent.width
                visible: MonitorModes.outputs.length === 0
                label: "Reading outputs…"
            }
        }
    }
}
