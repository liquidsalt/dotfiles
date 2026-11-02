import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

PanelWindow {
    id: root
    visible: false
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"

    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.layer: WlrLayer.Overlay
    // Cover the bar's reserved space too
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    screen: HyprlandIpc.focusedScreen

    property string sessionId: ""

    Process {
        running: true
        command: ["loginctl", "show-session", "auto", "-p", "Id", "--value"]
        stdout: StdioCollector { onStreamFinished: root.sessionId = text.trim() }
    }

    readonly property var actions: [
        { glyph: "", label: "Shut down", key: "s", argv: ["systemctl", "poweroff"] },
        { glyph: "", label: "Restart",   key: "r", argv: ["systemctl", "reboot"] },
        { glyph: "", label: "Lock",      key: "l", argv: ["hyprlock"] },
        { glyph: "", label: "Log out",   key: "o", argv: ["loginctl", "terminate-session", root.sessionId] }
    ]

    property int index: 0
    onVisibleChanged: if (visible) { root.index = 0; keys.forceActiveFocus(); }

    function run(argv) {
        Quickshell.execDetached(argv);
        root.visible = false;
    }

    IpcHandler {
        target: "powerMenu"
        function toggle() { root.visible = !root.visible; }
        function show()   { root.visible = true;  }
        function hide()   { root.visible = false; }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Glass.ink.r, Glass.ink.g, Glass.ink.b, 0.55)
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: root.visible

        Keys.onEscapePressed: root.visible = false
        Keys.onReturnPressed: root.run(root.actions[root.index].argv)
        Keys.onDownPressed:   root.index = (root.index + 1) % root.actions.length
        Keys.onUpPressed:     root.index = (root.index + root.actions.length - 1) % root.actions.length
        Keys.onPressed: (event) => {
            const t = event.text.toLowerCase();
            for (let i = 0; i < root.actions.length; i++) {
                if (root.actions[i].key === t) {
                    root.index = i;
                    root.run(root.actions[i].argv);
                    event.accepted = true;
                    return;
                }
            }
        }

        GlassSurface {
            anchors.centerIn: parent
            width:  Math.min(parent.width - 48, 300)
            height: col.implicitHeight + 12
            radius: Glass.launcherRadius

            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                spacing: 2

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width:  col.width
                        height: Glass.rowHeight + 2
                        radius: Glass.rowRadius
                        color: index === root.index ? Glass.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 110 } }

                        Row {
                            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                            spacing: 13

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 18
                                active: index === root.index
                                color: index === root.index ? Glass.accent : Glass.muted
                                text:  modelData.glyph
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 14
                                font.letterSpacing: -0.11
                                color: index === root.index ? Glass.text : Glass.muted
                                text:  modelData.label
                            }
                        }

                        Text {
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            font.family: Glass.fontMono
                            font.pixelSize: 11
                            color: Glass.faint
                            text:  modelData.key.toUpperCase()
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onEntered:    root.index = index
                            onClicked:    root.run(modelData.argv)
                        }
                    }
                }
            }
        }
    }
}
