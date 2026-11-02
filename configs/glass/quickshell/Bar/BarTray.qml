import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import "../Common"
import "../Services"
import "../Widgets"

Item {
    id: root
    implicitHeight: 20
    implicitWidth:  chip.implicitWidth

    property var activeMenuItem: null

    QsMenuOpener {
        id: menuOpener
        menu: root.activeMenuItem ? root.activeMenuItem.menu : null
    }

    Icon {
        id: chip
        anchors.centerIn: parent
        font.pixelSize: 17
        active: PopupState.owner === root
        text: ""
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var opening = PopupState.owner !== root;
            PopupState.toggle(root);
            if (opening) root.activeMenuItem = null;
        }
    }

    BarPopup {
        id: popup
        owner: root
        // 36 = 2 × (8 margin + 10 padding)
        popupWidth: Math.max(36 + (SystemTray.items.values.length === 0 ? emptyLabel.implicitWidth : iconsRow.implicitWidth),
                             root.activeMenuItem !== null ? 240 : 58)
        margins: 8
        spacing: 6
        onVisibleChanged: if (!visible) { root.activeMenuItem = null; }

        Item {
            width: parent.width
            height: 30

            RowLayout {
                id: iconsRow
                anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                spacing: 10
                visible: SystemTray.items.values.length > 0

                Repeater {
                    model: SystemTray.items

                    delegate: MouseArea {
                        id: trayCell
                        required property SystemTrayItem modelData
                        implicitHeight: 22
                        implicitWidth:  22
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28; height: 28; radius: 9
                            color: Glass.hover
                            visible: root.activeMenuItem === trayCell.modelData
                        }

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.MiddleButton) {
                                modelData.secondaryActivate();
                                PopupState.close();
                            } else if (mouse.button === Qt.RightButton) {
                                root.activeMenuItem =
                                    root.activeMenuItem === modelData ? null : modelData;
                            } else {
                                modelData.activate();
                                PopupState.close();
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: modelData.icon
                            smooth: true
                            mipmap: true
                            sourceSize.width:  22
                            sourceSize.height: 22
                        }
                    }
                }
            }

            Label {
                id: emptyLabel
                anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
                visible: SystemTray.items.values.length === 0
                color: Glass.faint
                text: "Nothing in the tray"
            }
        }

        Rectangle {
            visible: root.activeMenuItem !== null
            width: parent.width
            height: 1
            color: Glass.stroke
        }

        Column {
            visible: root.activeMenuItem !== null
            width: parent.width
            spacing: 0

            Repeater {
                model: menuOpener.children
                delegate: Item {
                    required property QsMenuEntry modelData
                    width: parent.width
                    implicitHeight: modelData.isSeparator ? 9 : 30

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors {
                            left: parent.left; right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8; rightMargin: 8
                        }
                        height: 1
                        color: Glass.stroke
                    }

                    Rectangle {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        radius: Glass.rowRadius
                        color: rowMouse.containsMouse && modelData.enabled
                            ? Glass.hover : "transparent"
                        Behavior on color { ColorAnimation { duration: 110 } }

                        Row {
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 10; rightMargin: 10
                            }
                            spacing: 8

                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 15
                                font.variableAxes: modelData.checkState === Qt.Checked
                                    ? Glass.iconActive : Glass.iconIdle
                                color: modelData.checkState === Qt.Checked ? Glass.text : Glass.muted
                                visible: modelData.buttonType !== QsMenuButtonType.None
                                text: {
                                    if (modelData.buttonType === QsMenuButtonType.CheckBox)
                                        return modelData.checkState === Qt.Checked ? "" : "";
                                    if (modelData.buttonType === QsMenuButtonType.RadioButton)
                                        return modelData.checkState === Qt.Checked ? "" : "";
                                    return "";
                                }
                            }

                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: 13
                                font.letterSpacing: -0.1
                                color: modelData.enabled ? Glass.text : Glass.faint
                                text: modelData.text.replace(/&/g, "")
                                width: parent.width - (submenuArrow.visible ? 22 : 0)
                                elide: Text.ElideRight
                            }
                        }

                        Icon {
                            id: submenuArrow
                            visible: modelData.hasChildren
                            anchors {
                                right: parent.right; verticalCenter: parent.verticalCenter
                                rightMargin: 10
                            }
                            font.pixelSize: 15
                            text: ""
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: modelData.enabled
                            onClicked: {
                                if (!modelData.hasChildren) {
                                    modelData.triggered();
                                    PopupState.close();
                                    root.activeMenuItem = null;
                                }
                            }
                        }
                    }
                }
            }

            Item {
                visible: menuOpener.children.length === 0
                width: parent.width
                height: 30
                Label {
                    anchors.centerIn: parent
                    color: Glass.faint
                    text: "No actions"
                }
            }
        }
    }
}
