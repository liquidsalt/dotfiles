import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import "../Services"
import "../Common"
import "../Widgets"

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }

    WlrLayershell.namespace: "quickshell:wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property string monName:     HyprlandIpc.focusedName
    readonly property string orientation: HyprlandIpc.focusedOrientation

    screen: HyprlandIpc.focusedScreen

    readonly property string activePath: WallpaperState.pathFor(root.monName)

    function isVideo(path) {
        const ext = path.split('.').pop().toLowerCase();
        return ["mp4", "mkv", "webm", "avi", "mov", "gif"].indexOf(ext) >= 0;
    }

    function apply(path) {
        WallpaperState.apply(root.monName, path);
        root.visible = false;
    }

    ListModel { id: wallpapers }

    readonly property string scanRoot: Config.wallpaperRootFor(root.orientation)

    Process {
        id: scanner
        running: false
        command: ["sh", "-c",
            "find \"$1\" -type f \\( " +
            "-iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' " +
            "-o -iname '*.gif' -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' " +
            "-o -iname '*.avi' -o -iname '*.mov'" +
            " \\) 2>/dev/null | sort",
            "sh", root.scanRoot]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim();
                if (p.length === 0) return;
                wallpapers.append({ path: p });
                if (p === root.activePath) {
                    const idx = wallpapers.count - 1;
                    carousel.currentIndex = idx;
                    carousel.positionViewAtIndex(idx, ListView.Center);
                }
            }
        }
    }

    IpcHandler {
        target: "wallpaperPicker"
        function toggle() {
            if (!root.visible) { wallpapers.clear(); scanner.running = true; }
            root.visible = !root.visible;
            if (root.visible) carousel.forceActiveFocus();
        }
        function hide() { root.visible = false; }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Glass.ink.r, Glass.ink.g, Glass.ink.b, 0.72)
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    GlassSurface {
        id: header
        anchors { top: parent.top; topMargin: 26; horizontalCenter: parent.horizontalCenter }
        width:  headerRow.implicitWidth + 36
        height: 40
        radius: 20

        Row {
            id: headerRow
            anchors.centerIn: parent
            spacing: 11

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 17
                color: Glass.accent
                text: ""
                rotation: root.orientation === "Vertical" ? 90 : 0
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: 13
                font.weight: Font.Medium
                font.letterSpacing: -0.13
                color: Glass.text
                text: root.monName
            }

            Rectangle {
                width: 1; height: 14
                color: Qt.rgba(1, 1, 1, 0.14)
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: root.orientation.toLowerCase() + " · " + wallpapers.count
                      + (wallpapers.count === 1 ? " image" : " images")
            }
        }
    }

    ListView {
        id: carousel
        anchors {
            top: header.bottom; topMargin: 26
            left: parent.left; right: parent.right
            bottom: footer.top; bottomMargin: 22
        }
        orientation: ListView.Horizontal
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - cellWidth) / 2
        preferredHighlightEnd:   (width + cellWidth) / 2
        model: wallpapers
        focus: true
        clip: true
        highlightMoveDuration: 140

        readonly property bool tall: root.orientation === "Vertical"
        readonly property int cellWidth:  tall ? 620 : 1000
        readonly property int frameW:     tall ? 430 : 900
        readonly property int frameH:     tall ? Math.min(height, 760) : Math.min(height, 560)

        MouseArea { anchors.fill: parent; onClicked: {} }

        Keys.onEscapePressed: root.visible = false
        Keys.onReturnPressed: {
            if (currentIndex >= 0 && currentIndex < count)
                root.apply(model.get(currentIndex).path);
        }
        Keys.onLeftPressed:  decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_H)      { decrementCurrentIndex(); event.accepted = true; }
            else if (event.key === Qt.Key_L) { incrementCurrentIndex(); event.accepted = true; }
        }

        delegate: Item {
            id: cell
            required property int index
            required property string path

            width:  carousel.cellWidth
            height: carousel.height

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool isVid:     root.isVideo(cell.path)
            readonly property bool isActive:  root.activePath === cell.path

            // ClippingRectangle because clip ignores rounded corners
            ClippingRectangle {
                id: frame
                anchors.centerIn: parent
                width:   cell.isCurrent ? carousel.frameW : Math.round(carousel.frameW * 0.4)
                height:  cell.isCurrent ? carousel.frameH : Math.round(carousel.frameH * 0.4)
                opacity: cell.isCurrent ? 1.0 : 0.38
                radius:  14
                color:   Glass.ink
                antialiasing: true

                border.width: cell.isActive ? 2 : 1
                border.color: cell.isActive  ? Glass.accent
                            : cell.isCurrent ? Qt.rgba(1, 1, 1, 0.22)
                            :                  "transparent"

                Behavior on width   { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                Behavior on height  { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 130 } }

                Image {
                    anchors.fill: parent
                    visible: !cell.isVid
                    source: cell.isVid ? "" : "file://" + cell.path
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // No preview for videos and gifs, decoding them all is too slow
                Item {
                    anchors.fill: parent
                    visible: cell.isVid
                    Icon {
                        anchors.centerIn: parent
                        font.pixelSize: 44
                        color: Glass.faint
                        text: ""
                    }
                }

                Rectangle {
                    visible: cell.isCurrent
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 34
                    color: Qt.rgba(Glass.ink.r, Glass.ink.g, Glass.ink.b, 0.72)

                    Label {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left; right: parent.right
                            leftMargin: 14; rightMargin: 14
                        }
                        horizontalAlignment: Text.AlignHCenter
                        color: Glass.text
                        elide: Text.ElideMiddle
                        text: cell.path.split("/").pop()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (cell.isCurrent) root.apply(cell.path);
                    else carousel.currentIndex = cell.index;
                }
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: wallpapers.count === 0
        font.pixelSize: 14
        text: "Nothing in " + root.scanRoot
    }

    GlassSurface {
        id: footer
        anchors { bottom: parent.bottom; bottomMargin: 26; horizontalCenter: parent.horizontalCenter }
        width:  footerText.implicitWidth + 34
        height: 32
        radius: 16

        Text {
            id: footerText
            anchors.centerIn: parent
            font.family: Glass.fontMono
            font.pixelSize: 10
            font.letterSpacing: 1.1
            color: Glass.faint
            text: "← →  BROWSE      ENTER  APPLY TO " + root.monName.toUpperCase() + "      ESC  CLOSE"
        }
    }
}
