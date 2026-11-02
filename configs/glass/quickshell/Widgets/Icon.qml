import QtQuick
import "../Common"

Text {
    property bool active: false

    font.family: Glass.fontIcon
    font.pixelSize: 16
    font.variableAxes: active ? Glass.iconActive : Glass.iconIdle
    color: active ? Glass.text : Glass.muted
}
