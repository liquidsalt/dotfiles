// Colours and sizes are copied from quickshell/Common/Glass.qml, the greeter runs before login and only sees this folder
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: ink

    readonly property color ink:    "#05070B"
    readonly property color panel:  Qt.rgba(0.071, 0.082, 0.110, 0.44)
    readonly property color stroke: Qt.rgba(1, 1, 1, 0.11)
    readonly property color hover:  Qt.rgba(1, 1, 1, 0.10)
    readonly property color text:   "#EDF0F5"
    readonly property color muted:  Qt.rgba(0.929, 0.941, 0.961, 0.56)
    readonly property color faint:  Qt.rgba(0.929, 0.941, 0.961, 0.28)
    readonly property color critical: "#FF8A80"
    readonly property color accent:   "#E2C9A2"

    readonly property string fontUi:   "sans-serif"
    readonly property string fontIcon: "Material Symbols Rounded"

    property int userIndex:    userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property var user:    users.count > 0 ? users.itemAt(userIndex) : null
    readonly property var session: sessions.count > 0 ? sessions.itemAt(sessionIndex) : null

    property string message: ""
    property var now: new Date()

    // Repeaters create every delegate, so the current user and session can be read by index
    Repeater {
        id: users
        model: userModel
        delegate: Item {
            required property string name
            required property string realName
            required property string icon
        }
    }

    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item {
            required property string name
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = "Wrong password";
            password.text = "";
            shake.restart();
        }
        function onLoginSucceeded() { root.message = ""; }
    }

    function login() {
        if (root.user) sddm.login(root.user.name, password.text, root.sessionIndex);
    }

    Image {
        id: background
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    // The glass: the background blurred, cut to the shape of every panel
    MultiEffect {
        anchors.fill: parent
        source: background
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: -0.05
        maskEnabled: true
        maskSource: shapes
    }

    Item {
        id: shapes
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Repeater {
            model: [card, sessionPill, powerPill]
            delegate: Rectangle {
                required property var modelData
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                radius: modelData.radius
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.25)
    }

    Column {
        id: clock
        anchors { horizontalCenter: parent.horizontalCenter; bottom: card.top; bottomMargin: 36 }
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font { family: root.fontUi; pixelSize: 96; weight: Font.Light; letterSpacing: -2 }
            color: root.text
            text: Qt.formatDateTime(root.now, "HH:mm")
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            font { family: root.fontUi; pixelSize: 17 }
            color: root.muted
            text: Qt.formatDateTime(root.now, "dddd d MMMM")
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        width: 340
        height: cardColumn.implicitHeight + 40
        radius: 18
        color: root.panel
        border { width: 1; color: root.stroke }

        SequentialAnimation {
            id: shake
            loops: 2
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -10; duration: 45 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 10;  duration: 90 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0;   duration: 45 }
        }

        Column {
            id: cardColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 16

            Rectangle {
                id: avatar
                anchors.horizontalCenter: parent.horizontalCenter
                width: 72
                height: 72
                radius: 36
                color: root.hover
                border { width: 1; color: root.stroke }
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    font { family: root.fontUi; pixelSize: 30; weight: Font.Medium }
                    color: root.text
                    text: root.user ? (root.user.realName || root.user.name).charAt(0).toUpperCase() : ""
                }

                Image {
                    id: face
                    anchors.fill: parent
                    source: root.user ? root.user.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: round
                    }
                }

                Rectangle {
                    id: round
                    anchors.fill: parent
                    radius: 36
                    visible: false
                    layer.enabled: true
                }
            }

            Item {
                width: parent.width
                height: 24

                Text {
                    anchors.centerIn: parent
                    font { family: root.fontUi; pixelSize: 17; weight: Font.Medium }
                    color: root.text
                    text: root.user ? (root.user.realName || root.user.name) : ""
                }

                IconButton {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    visible: users.count > 1
                    glyph: ""  // chevron_left
                    onClicked: root.userIndex = (root.userIndex + users.count - 1) % users.count
                }

                IconButton {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    visible: users.count > 1
                    glyph: ""  // chevron_right
                    onClicked: root.userIndex = (root.userIndex + 1) % users.count
                }
            }

            Rectangle {
                width: parent.width
                height: 42
                radius: 11
                color: root.hover
                border { width: 1; color: password.activeFocus ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.5) : root.stroke }

                TextInput {
                    id: password
                    anchors { left: parent.left; right: go.left; leftMargin: 14; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    font { family: root.fontUi; pixelSize: 15; letterSpacing: 1 }
                    color: root.text
                    selectionColor: root.accent
                    clip: true
                    onTextEdited: root.message = ""
                    Keys.onReturnPressed: root.login()
                    Keys.onEnterPressed:  root.login()
                    Keys.onEscapePressed: text = ""

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: password.text.length === 0
                        font: password.font
                        color: root.faint
                        text: "Password"
                    }
                }

                IconButton {
                    id: go
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    glyph: ""  // arrow_forward
                    onClicked: root.login()
                }
            }
        }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: card.bottom; topMargin: 14 }
        font { family: root.fontUi; pixelSize: 13 }
        color: root.message ? root.critical : root.muted
        text: root.message || (keyboard.capsLock ? "Caps Lock is on" : "")
    }

    Rectangle {
        id: sessionPill
        anchors { left: parent.left; bottom: parent.bottom; margins: 24 }
        width: sessionRow.implicitWidth + 28
        height: 40
        radius: 12
        color: root.panel
        border { width: 1; color: root.stroke }

        Row {
            id: sessionRow
            anchors.centerIn: parent
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font { family: root.fontIcon; pixelSize: 18 }
                color: root.muted
                text: ""  // desktop_windows
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font { family: root.fontUi; pixelSize: 13 }
                color: sessionArea.containsMouse ? root.text : root.muted
                text: root.session ? root.session.name : ""
            }
        }

        MouseArea {
            id: sessionArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: sessions.count > 1
            onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessions.count
        }
    }

    Rectangle {
        id: powerPill
        anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
        width: powerRow.implicitWidth + 12
        height: 40
        radius: 12
        color: root.panel
        border { width: 1; color: root.stroke }

        Row {
            id: powerRow
            anchors.centerIn: parent
            spacing: 2

            IconButton {
                visible: sddm.canSuspend
                glyph: ""  // bedtime
                onClicked: sddm.suspend()
            }
            IconButton {
                visible: sddm.canReboot
                glyph: ""  // restart_alt
                onClicked: sddm.reboot()
            }
            IconButton {
                visible: sddm.canPowerOff
                glyph: ""  // power_settings_new
                onClicked: sddm.powerOff()
            }
        }
    }

    component IconButton: Rectangle {
        id: button
        property string glyph
        signal clicked

        width: 30
        height: 30
        radius: 9
        color: area.containsMouse ? root.hover : "transparent"
        Behavior on color { ColorAnimation { duration: 110 } }

        Text {
            anchors.centerIn: parent
            font { family: root.fontIcon; pixelSize: 18 }
            color: area.containsMouse ? root.accent : root.muted
            text: button.glyph
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
