pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.island

RowLayout {
    id: root
    spacing: 12
    height: 54 // Explicit height to prevent centering jitter

    property alias searchInput: searchInput
    property bool animateWidth: false
    property string searchingText: LauncherSearch.query
    property var resultView: null

    function forceFocus() { searchInput.forceActiveFocus(); }
    
    signal activated

    // Prefix logic
    readonly property string actionPrefix: Config.options.search.prefix.action
    readonly property string appPrefix: Config.options.search.prefix.app
    readonly property string clipboardPrefix: Config.options.search.prefix.clipboard
    readonly property string emojisPrefix: Config.options.search.prefix.emojis
    readonly property string mathPrefix: Config.options.search.prefix.math
    readonly property string shellPrefix: Config.options.search.prefix.shellCommand
    readonly property string webPrefix: Config.options.search.prefix.webSearch
    readonly property string symbolsPrefix: Config.options.search.prefix.symbols ?? ""

    readonly property bool isSpecialMode: searchingText.startsWith(clipboardPrefix) || 
                                         searchingText.startsWith(emojisPrefix) ||
                                         (symbolsPrefix !== "" && searchingText.startsWith(symbolsPrefix))

    readonly property string iconText: {
        if (searchingText.startsWith(actionPrefix)) return "settings_suggest";
        if (searchingText.startsWith(appPrefix)) return "apps";
        if (searchingText.startsWith(clipboardPrefix)) return "content_paste_search";
        if (searchingText.startsWith(emojisPrefix)) return "add_reaction";
        if (searchingText.startsWith(mathPrefix)) return "calculate";
        if (searchingText.startsWith(shellPrefix)) return "terminal";
        if (searchingText.startsWith(webPrefix)) return "travel_explore";
        if (symbolsPrefix !== "" && searchingText.startsWith(symbolsPrefix)) return "emoji_symbols";
        return searchingText === "" ? "search" : "apps";
    }

    readonly property var iconShape: {
        if (searchingText.startsWith(actionPrefix)) return MaterialShape.Shape.Pill;
        if (searchingText.startsWith(appPrefix)) return MaterialShape.Shape.Clover4Leaf;
        if (searchingText.startsWith(clipboardPrefix)) return MaterialShape.Shape.Gem;
        if (searchingText.startsWith(emojisPrefix)) return MaterialShape.Shape.Sunny;
        if (searchingText.startsWith(mathPrefix)) return MaterialShape.Shape.PuffyDiamond;
        if (searchingText.startsWith(shellPrefix)) return MaterialShape.Shape.PixelCircle;
        if (searchingText.startsWith(webPrefix)) return MaterialShape.Shape.SoftBurst;
        return searchingText === "" ? MaterialShape.Shape.Cookie7Sided : MaterialShape.Shape.Clover4Leaf;
    }

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        Layout.leftMargin: 8

        MaterialShape {
            anchors.fill: parent
            color: Appearance.colors.colSecondaryContainer
            implicitSize: Math.max(width, height)
            shape: root.iconShape

            Behavior on color {
                ColorAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.bezierCurve: Appearance.animationCurves.emphasized
                }
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.iconText
            font.pixelSize: Appearance.font.pixelSize.huge
            color: Appearance.colors.colOnSecondaryContainer
        }
    }

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredHeight: 46
        Layout.fillWidth: true
        Layout.rightMargin: root.isSpecialMode ? 8 : 0

        readonly property int collapsedWidth: 240
        readonly property int expandedWidth: 420
        // Use implicitWidth only if not filling width
        implicitWidth: root.searchingText === "" ? collapsedWidth : expandedWidth

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.bezierCurve: Appearance.animationCurves.emphasized
            }
        }

        TextField {
            id: searchInput
            anchors.fill: parent
            leftPadding: 42 // Room for inner search icon
            rightPadding: 14
            topPadding: 0
            bottomPadding: 0
            font.family: Appearance.font.family.main
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSurface
            placeholderText: ""
            selectByMouse: true
            verticalAlignment: TextInput.AlignVCenter

            // Simple one-way text binding to avoid loops, 
            // query updates are handled by onTextChanged
            text: LauncherSearch.query
            onTextChanged: {
                if (activeFocus && text !== LauncherSearch.query) {
                    LauncherSearch.query = text;
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                    if (root.resultView && root.resultView.count > 0) {
                        root.resultView.focus = true;
                        event.accepted = true;
                    }
                }
            }

            background: Rectangle {
                radius: 23
                color: Appearance.colors.colLayer2
            }
            
            onAccepted: {
                if (root.resultView && root.resultView.count > 0) {
                    let firstItem = root.resultView.currentItem;
                    if (firstItem && firstItem.entry) {
                        firstItem.entry.execute();
                        root.activated();
                    }
                }
            }

            Keys.onEscapePressed: event => event.accepted = false
        }

        MaterialSymbol {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            font.pixelSize: 20
            color: Appearance.colors.colSubtext
            opacity: 0.7
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: searchInput.leftPadding
            anchors.right: parent.right
            anchors.rightMargin: searchInput.rightPadding
            anchors.verticalCenter: parent.verticalCenter
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenterOffset: 1
            text: Translation.tr("Search, calculate or run")
            color: Appearance.colors.colSubtext
            font: searchInput.font
            elide: Text.ElideRight
            opacity: searchInput.text === "" ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.bezierCurve: Appearance.animationCurves.emphasized
                }
            }
        }
    }

    IconToolbarButton {
        visible: !root.isSpecialMode
        Layout.alignment: Qt.AlignVCenter
        onClicked: {
            GlobalStates.overviewOpen = false;
            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
        }
        text: "image_search"
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        StyledToolTip {
            text: Translation.tr("Google Lens")
            y: parent.height + 3
        }
    }

    IconToolbarButton {
        id: songRecButton
        visible: !root.isSpecialMode
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 8
        toggled: SongRec.running
        onClicked: SongRec.toggleRunning()
        text: "music_cast"
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40

        StyledToolTip {
            text: Translation.tr("Recognize music")
            y: parent.height + 3
        }

        colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
        background: MaterialShape {
            RotationAnimation on rotation {
                running: songRecButton.toggled
                duration: 12000
                easing.type: Easing.Linear
                loops: Animation.Infinite
                from: 0
                to: 360
            }
            shape: {
                if (songRecButton.down) {
                    return songRecButton.toggled ? MaterialShape.Shape.Circle : MaterialShape.Shape.Square
                } else {
                    return songRecButton.toggled ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Circle
                }
            }
            color: {
                if (songRecButton.toggled) {
                    return songRecButton.hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                } else {
                    return songRecButton.hovered ? Appearance.colors.colSurfaceContainerHigh : "transparent"
                }
            }
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
