pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property var realPlayers: MprisController.players
    readonly property var meaningfulPlayers: filterDuplicatePlayers(realPlayers)
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
    property list<real> visualizerPoints: []

    Process {
        id: cavaProc
        running: mediaControlsLoader.active
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                // Parse `;`-separated values into the visualizerPoints array
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Component.onCompleted: console.log("[MediaControls] Main module initialized")

    function filterDuplicatePlayers(players) {
        let filtered = [];
        let used = new Set();

        for (let i = 0; i < players.length; ++i) {
            if (used.has(i))
                continue;
            let p1 = players[i];
            let group = [i];

            // Find duplicates by trackTitle prefix
            for (let j = i + 1; j < players.length; ++j) {
                let p2 = players[j];
                if (p1.trackTitle && p2.trackTitle && (p1.trackTitle.includes(p2.trackTitle) || p2.trackTitle.includes(p1.trackTitle)) || (p1.position - p2.position <= 2 && p1.length - p2.length <= 2)) {
                    group.push(j);
                }
            }

            // Pick the one with non-empty trackArtUrl, or fallback to the first
            let chosenIdx = group.find(idx => players[idx].trackArtUrl && players[idx].trackArtUrl.length > 0);
            if (chosenIdx === undefined)
                chosenIdx = group[0];

            filtered.push(players[chosenIdx]);
            group.forEach(idx => used.add(idx));
        }
        return filtered;
    }
    function updatePopupRectForShortcut() {
        const focusedMonitor = Hyprland.focusedMonitor;
        const screen = focusedMonitor?.screen || Quickshell.screens[0];
        if (screen) {
            const dynamicRect = GlobalStates.mediaPositions[screen.name];

            if (dynamicRect && dynamicRect.width > 0) {
                Persistent.states.media.popupRect = Qt.rect(dynamicRect.x, dynamicRect.y, dynamicRect.width, dynamicRect.height);
                return;
            }

            // Fallback to section-based heuristic if dynamic position is unknown
            let alignment = "center";
            const layouts = Config.options.bar.layouts;
            const isVertical = Config.options.bar.vertical;
            
            let section = layouts.center;
            let sectionIdx = 1; // 0: left, 1: center, 2: right
            let itemIdx = -1;

            if (layouts.left.some(item => item.id === "music_player")) {
                section = layouts.left;
                sectionIdx = 0;
            } else if (layouts.right.some(item => item.id === "music_player")) {
                section = layouts.right;
                sectionIdx = 2;
            } else {
                section = layouts.center;
                sectionIdx = 1;
            }

            itemIdx = section.findIndex(item => item.id === "music_player");
            if (itemIdx === -1) itemIdx = section.length / 2;

            // Progress within the section (0.0 to 1.0)
            let sectionProgress = section.length > 1 ? itemIdx / (section.length - 1) : 0.5;
            
            // Progress across the whole screen (0.0 to 1.0)
            let totalProgress = (sectionIdx + sectionProgress) / 3;

            let x = 0;
            let y = 0;
            let width = focusedMonitor.width;
            let height = focusedMonitor.height;

            if (isVertical) {
                height = root.widgetHeight;
                y = (focusedMonitor.height - height) * totalProgress;
                width = 1;
            } else {
                width = root.widgetWidth;
                x = (focusedMonitor.width - width) * totalProgress;
                height = 1;
            }

            Persistent.states.media.popupRect = Qt.rect(x, y, width, height);
        }
    }

    function toggleShortcut() {
        GlobalStates.superReleaseMightTrigger = false;
        if (!GlobalStates.mediaControlsOpen) root.updatePopupRectForShortcut();
        GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
        if (GlobalStates.mediaControlsOpen)
            Notifications.timeoutAll();
    }

    Loader {
        id: mediaControlsLoader
        active: GlobalStates.mediaControlsOpen && !Config.options.island.enable
        onActiveChanged: {
            if (!mediaControlsLoader.active && root.realPlayers.length === 0) {
                GlobalStates.mediaControlsOpen = false;
            }
        }

        sourceComponent: PanelWindow {
            id: panelWindow
            visible: true
            screen: Hyprland.focusedMonitor?.screen || Quickshell.screens[0]
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth
            implicitHeight: playerColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"
            
            readonly property var rect: Persistent.states.media.popupRect
            readonly property real barThickness: {
                if (Config.options.bar.vertical) {
                    return Config.options.bar.sizes.width || 40;
                } else {
                    return Config.options.bar.sizes.height || 40;
                }
            }
            anchors {
                top: true
                left: !Config.options.bar.vertical || !Config.options.bar.bottom
                right: Config.options.bar.vertical && Config.options.bar.bottom
            }
            margins {
                top: {
                    if (rect.width === 0) return 0;
                    if (Config.options.bar.vertical) {
                        let targetY = rect.y + (rect.height / 2) - (panelWindow.implicitHeight / 2);
                        return Math.max(0, Math.min(targetY, screen.height - panelWindow.implicitHeight));
                    } else {
                        if (!Config.options.bar.bottom) {
                            return barThickness;
                        } else {
                            return screen.height - barThickness - panelWindow.implicitHeight;
                        }
                    }
                }
                left: {
                    if (rect.width === 0) return 0;
                    if (Config.options.bar.vertical) {
                        if (!Config.options.bar.bottom) {
                            return barThickness;
                        }
                        return 0;
                    } else {
                        let targetX = rect.x + (rect.width / 2) - (panelWindow.implicitWidth / 2);
                        return Math.max(0, Math.min(targetX, screen.width - panelWindow.implicitWidth));
                    }
                }
                right: {
                    if (rect.width === 0) return 0;
                    if (Config.options.bar.vertical && Config.options.bar.bottom) {
                        return barThickness;
                    }
                    return 0;
                }
            }

            mask: Region {
                id: panelWindowMask
                item: playerColumnLayout
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.mediaControlsOpen = false;
                }
            }

            ColumnLayout {
                id: playerColumnLayout
                anchors.fill: parent
                spacing: -Appearance.sizes.elevationMargin // Shadow overlap okay

                Repeater {
                    model: ScriptModel {
                        values: root.meaningfulPlayers
                    }
                    delegate: PlayerControl {
                        id: playerInstance
                        required property MprisPlayer modelData
                        player: modelData
                        visualizerPoints: root.visualizerPoints
                        implicitWidth: root.widgetWidth
                        implicitHeight: playerInstance.showLyrics ? 350 : root.widgetHeight
                        radius: root.popupRounding
                    }
                }

                Item {
                    // No player placeholder
                    Layout.alignment: {
                        if (panelWindow.anchors.left)
                            return Qt.AlignLeft;
                        if (panelWindow.anchors.right)
                            return Qt.AlignRight;
                        return Qt.AlignHCenter;
                    }
                    Layout.leftMargin: Appearance.sizes.hyprlandGapsOut
                    Layout.rightMargin: Appearance.sizes.hyprlandGapsOut
                    visible: root.meaningfulPlayers.length === 0
                    implicitWidth: placeholderBackground.implicitWidth + Appearance.sizes.elevationMargin
                    implicitHeight: placeholderBackground.implicitHeight + Appearance.sizes.elevationMargin

                    StyledRectangularShadow {
                        target: placeholderBackground
                    }

                    Rectangle {
                        id: placeholderBackground
                        anchors.centerIn: parent
                        color: Appearance.colors.colLayer0
                        radius: root.popupRounding
                        property real padding: 20
                        implicitWidth: placeholderLayout.implicitWidth + padding * 2
                        implicitHeight: placeholderLayout.implicitHeight + padding * 2

                        ColumnLayout {
                            id: placeholderLayout
                            anchors.centerIn: parent

                            StyledText {
                                text: Translation.tr("No active player")
                                font.pixelSize: Appearance.font.pixelSize.large
                            }
                            StyledText {
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Make sure your player has MPRIS support\nor try turning off duplicate player filtering")
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            root.toggleShortcut();
        }

        function close(): void {
            GlobalStates.mediaControlsOpen = false;
        }

        function open(): void {
            GlobalStates.superReleaseMightTrigger = false;
            root.updatePopupRectForShortcut();
            GlobalStates.mediaControlsOpen = true;
            Notifications.timeoutAll();
        }
    }

    IpcHandler {
        target: "mediaControlsToggle"
        function handle(): void {
            root.toggleShortcut();
        }
        function toggle(): void {
            root.toggleShortcut();
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"

        onPressed: {
            root.toggleShortcut();
        }
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: {
            root.updatePopupRectForShortcut();
            GlobalStates.mediaControlsOpen = true;
        }
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: {
            GlobalStates.mediaControlsOpen = false;
        }
    }
}
