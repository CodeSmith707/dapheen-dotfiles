import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.showing
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    property bool showing: false
    property bool dragging: false
    property string snapPosition: "center"
    property real dragMargin: 12
    property real panelWidth: Math.min(1000, root.width - 64)
    property real panelHeight: Math.min(650, root.height - 64)
    property real panelX: (root.width - panelWidth) / 2
    property real panelY: (root.height - panelHeight) / 2
    property real tiltX: 0
    property real tiltY: 0

    function toggle() { showing = !showing }
    function hide() { showing = false; dragging = false }

    function clampX(v) {
        return Math.max(dragMargin, Math.min(root.width - panelWidth - dragMargin, v))
    }

    function clampY(v) {
        return Math.max(dragMargin, Math.min(root.height - panelHeight - dragMargin, v))
    }

    function snapTo(pos) {
        snapPosition = pos
        const centerW = Math.min(1000, root.width - 64)
        const centerH = Math.min(650, root.height - 64)
        switch (pos) {
        case "top":
            panelWidth = centerW
            panelHeight = Math.min(centerH * 0.6, root.height - 2 * dragMargin)
            panelX = (root.width - panelWidth) / 2
            panelY = dragMargin
            break
        case "bottom":
            panelWidth = centerW
            panelHeight = Math.min(centerH * 0.6, root.height - 2 * dragMargin)
            panelX = (root.width - panelWidth) / 2
            panelY = root.height - panelHeight - dragMargin
            break
        case "left":
            panelWidth = Math.min(centerW * 0.55, root.width - 2 * dragMargin)
            panelHeight = Math.min(centerH * 1.15, root.height - 2 * dragMargin)
            panelX = dragMargin
            panelY = (root.height - panelHeight) / 2
            break
        case "right":
            panelWidth = Math.min(centerW * 0.55, root.width - 2 * dragMargin)
            panelHeight = Math.min(centerH * 1.15, root.height - 2 * dragMargin)
            panelX = root.width - panelWidth - dragMargin
            panelY = (root.height - panelHeight) / 2
            break
        default:
            panelWidth = centerW
            panelHeight = centerH
            panelX = (root.width - panelWidth) / 2
            panelY = (root.height - panelHeight) / 2
            break
        }
    }

    function finishDrag() {
        dragging = false
        snapPosition = "free"
    }

    Behavior on tiltX { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Behavior on tiltY { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    onWidthChanged: if (root.width > 0 && root.height > 0 && snapPosition !== "free") snapTo(snapPosition)
    onHeightChanged: if (root.width > 0 && root.height > 0 && snapPosition !== "free") snapTo(snapPosition)

    mask: Region {
        item: root.showing ? backdrop : null
    }

    IpcHandler {
        target: "keybinds"
        function toggle(): void { root.toggle() }
        function hide(): void { root.hide() }
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "transparent"
        visible: root.showing
        focus: root.showing

        Keys.onEscapePressed: root.hide()

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        Rectangle {
            id: panel
            x: root.panelX
            y: root.panelY
            width: root.panelWidth
            height: root.panelHeight
            clip: true

            property real tiltX: root.tiltX
            property real tiltY: root.tiltY

            transform: [
                Rotation {
                    origin.x: panel.width / 2
                    origin.y: panel.height / 2
                    axis { x: 1; y: 0; z: 0 }
                    angle: panel.tiltX
                },
                Rotation {
                    origin.x: panel.width / 2
                    origin.y: panel.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: panel.tiltY
                }
            ]

            Behavior on x { enabled: !root.dragging; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !root.dragging; NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            color: Theme.bg
            radius: Theme.radius
            border.color: Theme.accent
            border.width: 1

            // Decorative corners matching SettingsWindow
            Rectangle {
                width: 40
                height: 2
                anchors { top: parent.top; left: parent.left; margins: 14 }
                color: Theme.accent2
            }
            Rectangle {
                width: 2
                height: 40
                anchors { top: parent.top; left: parent.left; margins: 14 }
                color: Theme.accent2
            }
            Rectangle {
                width: 40
                height: 2
                anchors { bottom: parent.bottom; right: parent.right; margins: 14 }
                color: Theme.accent2
            }
            Rectangle {
                width: 2
                height: 40
                anchors { bottom: parent.bottom; right: parent.right; margins: 14 }
                color: Theme.accent2
            }

            // Eat clicks inside the panel so only outside clicks dismiss it.
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {}
                onPositionChanged: function(mouse) {
                    if (root.dragging || panel.width <= 0 || panel.height <= 0) return
                    const nx = mouse.x / panel.width - 0.5
                    const ny = mouse.y / panel.height - 0.5
                    root.tiltX = Math.max(-4, Math.min(4, -ny * 8))
                    root.tiltY = Math.max(-4, Math.min(4, nx * 8))
                }
                onExited: {
                    root.tiltX = 0
                    root.tiltY = 0
                }
            }

            // Center handle: drag to relocate; tap an arrow to snap and resize.
            Item {
                id: positionHandle
                width: 172
                height: 18
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                z: 20

                Rectangle {
                    anchors.fill: parent
                    radius: 7
                    color: Theme.bg
                    border.color: Theme.accent
                    border.width: 1
                    opacity: 0.96
                }

                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    anchors.bottomMargin: -3
                    acceptedButtons: Qt.LeftButton
                    cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property real pressX: 0
                    property real pressY: 0
                    property real startX: 0
                    property real startY: 0
                    property bool moved: false

                    onPressed: function(mouse) {
                        const p = dragArea.mapToItem(backdrop, mouse.x, mouse.y)
                        pressX = p.x
                        pressY = p.y
                        startX = root.panelX
                        startY = root.panelY
                        moved = false
                        root.dragging = true
                    }
                    onPositionChanged: function(mouse) {
                        if (!root.dragging || !pressed) return
                        const p = dragArea.mapToItem(backdrop, mouse.x, mouse.y)
                        if (Math.abs(p.x - pressX) + Math.abs(p.y - pressY) > 3) moved = true
                        root.panelX = Math.max(root.dragMargin, Math.min(root.width - root.panelWidth - root.dragMargin, startX + p.x - pressX))
                        root.panelY = Math.max(root.dragMargin, Math.min(root.height - root.panelHeight - root.dragMargin, startY + p.y - pressY))
                    }
                    onReleased: {
                        if (moved) root.finishDrag()
                        else root.dragging = false
                    }
                    onCanceled: {
                        if (moved) root.finishDrag()
                        else root.dragging = false
                    }
                    onDoubleClicked: root.snapTo("center")
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    z: 2
                    Repeater {
                        model: [
                            { glyph: "◀", pos: "left" },
                            { glyph: "▲", pos: "top" },
                            { glyph: "●", pos: "center" },
                            { glyph: "▼", pos: "bottom" },
                            { glyph: "▶", pos: "right" }
                        ]
                        delegate: Text {
                            required property var modelData
                            text: modelData.glyph
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: modelData.pos === "left" || modelData.pos === "right" ? 7 : 9
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.snapTo(modelData.pos)
                            }
                        }
                    }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 16
                clip: true

                Row {
                    spacing: 10

                    Text {
                        text: "󰌌"
                        color: Theme.accent
                        font.family: Theme.iconFont
                        font.pixelSize: 20
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "KEYBINDINGS"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                        font.bold: true
                        font.letterSpacing: 4
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                Row {
                    id: columns
                    width: parent.width
                    height: parent.height - 58
                    spacing: 18
                    clip: true

                    // Column 1
                    Column {
                        width: (columns.width - 40) / 3
                        height: columns.height
                        spacing: 10
                        clip: true

                        Row {
                            spacing: 7
                                                        Text {
                                text: "󰀻"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "APPS & LAUNCHERS"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                        }

                        Repeater {
                            model: [
                                ["SUPER + T", "Terminal"],
                                ["SUPER + D", "App launcher"],
                                ["SUPER + S", "Wheel launcher"],
                                ["SUPER + E", "File manager"],
                                ["SUPER + B", "Browser"],
                                ["SUPER + Q", "Close window"],
                                ["SUPER + TAB", "Lock screen"]
                            ]
                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: modelData[0]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 126
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    text: "—"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData[1]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: Math.max(40, parent.width - 150)
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        Row {
                            spacing: 7
                            Text {
                                text: "󰍹"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "WORKSPACES"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                        }

                        Repeater {
                            model: [
                                ["SUPER + 1–9", "Switch workspace"],
                                ["SUPER + 0", "Workspace 10"],
                                ["SUPER + SHIFT + 1–0", "Move window"],
                                ["ALT + TAB", "Scroll Overview"]
                            ]
                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: modelData[0]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 126
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    text: "—"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData[1]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: Math.max(40, parent.width - 150)
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        height: columns.height
                        color: Theme.border
                    }

                    // Column 2
                    Column {
                        width: (columns.width - 40) / 3
                        height: columns.height
                        spacing: 10
                        clip: true

                        Row {
                            spacing: 7
                                                        Text {
                                text: "󰖲"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "WINDOW MANAGEMENT"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                        }

                        Repeater {
                            model: [
                                ["SUPER + F", "Fullscreen"],
                                ["SUPER + SPACE", "Float and center"],
                                ["SUPER + ARROWS", "Focus windows"],
                                ["SUPER + SHIFT + ARROWS", "Move window"]
                            ]
                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: modelData[0]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 126
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    text: "—"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData[1]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: Math.max(40, parent.width - 150)
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        // Match the vertical start of the second section in column 1.
                        Item { height: 24; width: 1 }

                        Row {
                            spacing: 7
                            Text {
                                text: "󰆍"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "QUICKSHELL"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                        }

                        Repeater {
                            model: [
                                ["SUPER + GRAVE", "Power menu"],
                                ["SUPER + I", "Settings"],
                                ["SUPER + W", "Wallpapers"],
                                ["SUPER + N", "Notifications"],
                                ["SUPER + C", "To-do panel"],
                                ["SUPER + ,", "Emoji picker"],
                                ["SUPER + SHIFT + W", "Toggle bar"]
                            ]
                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: modelData[0]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 126
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    text: "—"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData[1]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: Math.max(40, parent.width - 150)
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        height: columns.height
                        color: Theme.border
                    }

                    // Column 3
                    Column {
                        width: (columns.width - 40) / 3
                        height: columns.height
                        spacing: 10
                        clip: true

                        Row {
                            spacing: 7
                                                        Text {
                                text: "󰒓"
                                color: Theme.accent
                                font.family: Theme.iconFont
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "SYSTEM & UTILITIES"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                            }
                        }

                        Repeater {
                            model: [
                                ["SUPER + O", "Opacity script"],
                                ["SUPER + L", "Theme / focus right*"],
                                ["SUPER + X", "Keyboard layout"],
                                ["SUPER + V", "Clipboard history"],
                                ["DELETE", "Full screenshot"],
                                ["SHIFT + DELETE", "Area screenshot"],
                                ["SUPER + R", "Screen recording"],
                                ["SUPER + SHIFT + E", "Exit Hyprland"]
                            ]
                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: 4

                                Text {
                                    text: modelData[0]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 126
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    text: "—"
                                    color: Theme.accent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: 12
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData[1]
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    width: Math.max(40, parent.width - 150)
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        Row {
    spacing: 7

    Text {
        text: "󰎆"
        color: Theme.accent
        font.family: Theme.iconFont
        font.pixelSize: 14
        anchors.verticalCenter: parent.verticalCenter
    }
    Text {
        text: "MEDIA"
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}

// Media keybindings aligned with the sections above.
Repeater {
    model: [
        ["Volume keys", "Adjust volume"],
        ["Mute", "Toggle mute"],
        ["Play / Next / Previous", "Media controls"]
    ]

    delegate: Row {
        required property var modelData
        width: parent.width
        spacing: 4

        Text {
            text: modelData[0]
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 11
            width: 126
            wrapMode: Text.Wrap
        }

        Text {
            text: "—"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 11
            width: 12
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: modelData[1]
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 11
            width: Math.max(40, parent.width - 150)
            wrapMode: Text.Wrap
        }
    }
}

Text {
    text: "Click outside or press ESC to close."
    color: Theme.textDim
    font.family: Theme.fontFamily
    font.pixelSize: 11
    width: parent.width
    wrapMode: Text.Wrap
    topPadding: 14
}
                    }
                }
            }
        }
    }
}