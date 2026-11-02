import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    readonly property int maxRows: 8

    property string query: ""
    onVisibleChanged: if (!visible) { root.query = ""; input.text = ""; }
    onQueryChanged: list.currentIndex = 0

    screen: HyprlandIpc.focusedScreen

    function rank(app, q) {
        const name = (app.name || "").toLowerCase();
        if (name.startsWith(q)) return 0;

        const words = name.split(" ");
        for (let i = 1; i < words.length; i++)
            if (words[i].startsWith(q)) return 1;

        if (name.indexOf(q) !== -1) return 2;

        const generic = (app.genericName || "").toLowerCase();
        if (generic.indexOf(q) !== -1) return 3;

        const cats = app.categories ? app.categories.toString().toLowerCase() : "";
        if (cats.indexOf(q) !== -1) return 4;

        return -1;
    }

    readonly property var filtered: {
        const q = root.query.trim().toLowerCase();
        if (q.length === 0) return [];

        const all = DesktopEntries.applications.values;
        let hits = [];
        for (let i = 0; i < all.length; i++) {
            const r = root.rank(all[i], q);
            if (r >= 0) hits.push({ rank: r, idx: i, app: all[i] });
        }
        hits.sort((a, b) => a.rank - b.rank || a.idx - b.idx);
        return hits.slice(0, root.maxRows).map(h => h.app);
    }

    function launch(app) {
        if (!app) return;
        app.execute();
        root.visible = false;
    }

    IpcHandler {
        target: "launcher"
        function toggle() { root.visible = !root.visible; if (root.visible) input.forceActiveFocus(); }
        function show()   { root.visible = true;  input.forceActiveFocus(); }
        function hide()   { root.visible = false; root.query = ""; }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Glass.ink.r, Glass.ink.g, Glass.ink.b, 0.5)
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    GlassSurface {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.13)
        width: Math.min(parent.width - 48, Glass.launcherWidth)
        radius: Glass.launcherRadius

        height: 52 + (results.visible ? results.height : 0)
        Behavior on height {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        MouseArea { anchors.fill: parent; onClicked: {} }

        Item {
            id: field
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 52

            Icon {
                id: magnifier
                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                font.pixelSize: 19
                color: Glass.faint
                text: ""
            }

            TextInput {
                id: input
                anchors {
                    left: magnifier.right; leftMargin: 12
                    right: counter.left;   rightMargin: 12
                    verticalCenter: parent.verticalCenter
                }
                verticalAlignment: TextInput.AlignVCenter
                font.family: Glass.fontUi
                font.pixelSize: 16
                font.letterSpacing: -0.2
                color: Glass.text
                selectionColor: Qt.rgba(1, 1, 1, 0.22)
                selectByMouse: true
                clip: true

                onTextChanged: root.query = text

                Keys.onEscapePressed: root.visible = false
                Keys.onReturnPressed: root.launch(root.filtered[list.currentIndex])
                Keys.onDownPressed:   if (list.count > 0) list.incrementCurrentIndex()
                Keys.onUpPressed:     if (list.count > 0) list.decrementCurrentIndex()

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: input.text.length === 0
                    font: input.font
                    color: Glass.faint
                    text: "Search applications"
                }
            }

            Text {
                id: counter
                anchors { right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
                font.family: Glass.fontMono
                font.pixelSize: 10
                font.letterSpacing: 1.2
                color: Glass.faint
                text: {
                    if (root.query.trim().length === 0) return "";
                    const n = root.filtered.length;
                    return n === 0 ? "NO MATCHES"
                         : n === 1 ? "1 MATCH"
                         :           n + " MATCHES";
                }
            }
        }

        Item {
            id: results
            anchors { left: parent.left; right: parent.right; top: field.bottom }
            visible: root.filtered.length > 0
            height: visible ? list.contentHeight + 10 : 0

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            ListView {
                id: list
                anchors { fill: parent; margins: 5; topMargin: 6 }
                interactive: false
                model: root.filtered
                currentIndex: 0

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width:  list.width
                    height: Glass.rowHeight
                    radius: Glass.rowRadius
                    color: index === list.currentIndex ? Glass.hover : "transparent"
                    Behavior on color { ColorAnimation { duration: 110 } }

                    Row {
                        anchors { fill: parent; leftMargin: 13; rightMargin: 13 }
                        spacing: 12

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 20; height: 20
                            smooth: true
                            mipmap: true
                            sourceSize.width:  20
                            sourceSize.height: 20
                            source: Quickshell.iconPath(modelData.icon, true)
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 130
                            font.pixelSize: 14
                            font.letterSpacing: -0.11
                            color: index === list.currentIndex ? Glass.text : Glass.muted
                            text:  modelData.name
                            elide: Text.ElideRight
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 11
                            color: Glass.faint
                            text:  modelData.categories && modelData.categories.length > 0
                                   ? modelData.categories[0] : ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onEntered:    list.currentIndex = index
                        onClicked:    root.launch(modelData)
                    }
                }
            }
        }
    }
}
