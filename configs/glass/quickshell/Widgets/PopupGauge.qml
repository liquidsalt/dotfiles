import QtQuick
import "../Common"

Item {
    id: root

    property string glyph:     ""
    property string glyphFont: Glass.fontIcon
    property real   glyphSize: 16
    property string title:     ""
    property int    value:     0
    property int    alertAt:   101
    property var    detail:    []
    property color  tint:      Glass.muted

    readonly property bool alert: value >= alertAt

    implicitHeight: 24 + lines.implicitHeight + 9

    Text {
        id: mark
        anchors { left: parent.left; leftMargin: 10; top: parent.top; topMargin: 2 }
        font.family: root.glyphFont
        font.pixelSize: root.glyphSize
        font.variableAxes: Glass.iconIdle
        color: root.alert ? Glass.critical : Glass.muted
        text:  root.glyph
    }

    Label {
        id: pct
        anchors { right: parent.right; rightMargin: 10; top: parent.top; topMargin: 2 }
        font.pixelSize: 13
        font.features: Glass.tnum
        color: root.alert ? Glass.critical : Glass.text
        text:  root.value + "%"
    }

    Label {
        id: name
        anchors {
            left:  mark.right; leftMargin: 10
            right: pct.left;   rightMargin: 8
            baseline: pct.baseline
        }
        font.pixelSize: 13
        font.letterSpacing: -0.1
        color: Glass.text
        text:  root.title
        elide: Text.ElideRight
    }

    Column {
        id: lines
        anchors { left: name.left; right: parent.right; rightMargin: 10; top: name.bottom; topMargin: 1 }
        spacing: 0

        Repeater {
            model: root.detail
            delegate: Label {
                required property var modelData
                width: lines.width
                font.pixelSize: 11
                color: Glass.faint
                text:  modelData
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        anchors {
            left: name.left; right: parent.right; rightMargin: 10
            bottom: parent.bottom; bottomMargin: 5
        }
        height: 3
        radius: 1.5
        color: Qt.rgba(1, 1, 1, 0.09)

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width:  parent.width * Math.max(0, Math.min(100, root.value)) / 100
            radius: 1.5
            color:  root.alert ? Glass.critical : root.tint
            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        }
    }
}
