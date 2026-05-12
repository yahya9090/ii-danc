pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.island
import qs.services
import qs

Scope {
    id: scope

    // State sources
    readonly property var topNotif: Notifications.popupList[0] ?? null
    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool mediaActive: player !== null && player.playbackState === MprisPlaybackState.Playing

    readonly property bool launcherOpen: GlobalStates.overviewOpen
    readonly property bool overviewOpen: GlobalStates.workspacesOverviewOpen

    property bool _notifActive: false
    property var _lastNotif: null

    // OSD payload
    property bool _osdActive: false
    property string osdMode: "volume"
    property string osdIcon: "volume_up"
    property string osdLabel: ""
    property real osdValue: 0
    property real osdFrom: 0
    property real osdTo: 1.0
    property var  osdShape: MaterialShape.Shape.Circle
    property string osdProtectionMessage: ""

    // Battery peek state
    property bool _batteryActive: false
    property bool _seededCharging: false
    property bool _lastCharging: Battery.isCharging
    property var  _lastChargeState: Battery.chargeState

    function triggerBatteryIsland() {
        scope._batteryActive = true;
        scope.peeking = true;
        peekTimer.restart();
        batteryHide.restart();
    }

    // Auto-peek: short force-expand window after fresh notif/battery event
    property bool peeking: false

    // Resolved priority: overview > launcher > osd > battery > notif > media > home (idle)
    readonly property string mode: {
        if (GlobalStates.islandDebugMode !== "none") return GlobalStates.islandDebugMode;
        if (overviewOpen)             return "overview";
        if (launcherOpen)             return "launcher";
        if (_osdActive)               return "osd";
        if (_batteryActive)           return "battery";
        if (_notifActive && topNotif) return "notif";
        if (player !== null && (mediaActive || GlobalStates.mediaControlsOpen)) return "media";
        if (GlobalStates.mediaControlsOpen) return "media";
        return "home";
    }

    // Notif timing
    onTopNotifChanged: {
        if (topNotif && topNotif !== _lastNotif) {
            _lastNotif = topNotif;
            _notifActive = true;
            notifTimer.restart();
            scope.peeking = true;
            peekTimer.restart();
        } else if (!topNotif) {
            _notifActive = false;
            notifTimer.stop();
        }
    }

    Timer {
        id: notifTimer
        interval: Constants.notifTimeoutMs
        repeat: false
        onTriggered: scope._notifActive = false
    }

    Timer {
        id: peekTimer
        interval: Constants.peekDurationMs
        repeat: false
        onTriggered: scope.peeking = false
    }

    // OSD inputs
    function triggerOsd() {
        scope._osdActive = true;
        osdHide.restart();
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (!Audio.ready) return;
            scope.osdProtectionMessage = "";
            scope.osdMode = "volume";
            scope.osdIcon = Audio.sink.audio.muted ? "volume_off" : (Audio.sink.audio.volume < 0.01 ? "volume_mute" : (Audio.sink.audio.volume < 0.5 ? "volume_down" : "volume_up"));
            scope.osdLabel = Translation.tr("Volume");
            scope.osdValue = Audio.sink.audio.volume;
            scope.osdFrom = 0;
            scope.osdTo = 1.0;
            scope.osdShape = MaterialShape.Shape.Cookie7Sided;
            scope.triggerOsd();
        }
        function onMutedChanged() { onVolumeChanged(); }
    }

    Connections {
        target: Audio
        function onSinkProtectionTriggered(reason) {
            scope.osdProtectionMessage = reason;
            scope.osdMode = "volume";
            scope.osdIcon = "dangerous";
            scope.osdLabel = Translation.tr("Volume");
            scope.osdValue = Audio.sink?.audio?.volume ?? 0;
            scope.osdFrom = 0;
            scope.osdTo = 1.0;
            scope.osdShape = MaterialShape.Shape.Square;
            scope.triggerOsd();
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged(monitor) {
            if (monitor) {
                scope.osdProtectionMessage = "";
                scope.osdMode = "brightness";
                scope.osdIcon = Hyprsunset.temperatureActive ? "routine" : "light_mode";
                scope.osdLabel = Translation.tr("Brightness");
                scope.osdValue = monitor.brightness;
                scope.osdFrom = 0;
                scope.osdTo = 1.0;
                scope.osdShape = MaterialShape.Shape.Burst;
                scope.triggerOsd();
            }
        }
    }

    Connections {
        target: Hyprsunset
        function onGammaChangeAttempt() {
            scope.osdProtectionMessage = "";
            scope.osdMode = "gamma";
            scope.osdIcon = "wb_twilight";
            scope.osdLabel = Translation.tr("Gamma");
            scope.osdValue = Hyprsunset.gamma / 100;
            scope.osdFrom = Hyprsunset.gammaLowerLimit / 100;
            scope.osdTo = 1.0;
            scope.osdShape = MaterialShape.Shape.Circle;
            scope.triggerOsd();
        }
    }

    Connections {
        target: MprisController.activePlayer ?? null
        function onVolumeChanged() {
            if (MprisController.canChangeVolume) {
                scope.osdProtectionMessage = "";
                scope.osdMode = "media";
                scope.osdIcon = "music_note";
                scope.osdLabel = Translation.tr("Music");
                scope.osdValue = MprisController.activePlayer.volume;
                scope.osdFrom = 0;
                scope.osdTo = 1.0;
                scope.osdShape = MaterialShape.Shape.Cookie4Sided;
                scope.triggerOsd();
            }
        }
    }

    Timer {
        id: osdHide
        interval: Config.options.osd.timeout
        onTriggered: {
            scope._osdActive = false;
            scope.osdProtectionMessage = "";
        }
    }

    // Battery transitions
    Connections {
        target: Battery
        function onIsChargingChanged() {
            if (!scope._seededCharging) {
                scope._lastCharging = Battery.isCharging;
                scope._lastChargeState = Battery.chargeState;
                scope._seededCharging = true;
                return;
            }
            if (Battery.isCharging !== scope._lastCharging) {
                scope._lastCharging = Battery.isCharging;
                scope.triggerBatteryIsland();
            }
        }
        function onChargeStateChanged() {
            if (!scope._seededCharging) return;
            if (Battery.chargeState !== scope._lastChargeState) {
                scope._lastChargeState = Battery.chargeState;
                scope.triggerBatteryIsland();
            }
        }
    }
    Timer {
        id: batteryHide
        interval: Constants.batteryPeekMs
        onTriggered: scope._batteryActive = false
    }

    Variants {
        id: islandVariants
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData
            visible: true
            
            readonly property var launcherView: _launcherView
            readonly property bool barIsPushing: GlobalStates.barPushingStates[modelData.name] ?? true
            readonly property bool barOnTop: !Config.options.bar.bottom && !Config.options.bar.vertical
            
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: (Config.options.island.pushWindows && GlobalStates.islandPinned && !container.idleHidden && !(GlobalStates.barOpen && barOnTop)) ? Constants.notchClosedHeight : 0
            WlrLayershell.namespace: "quickshell:island"
            WlrLayershell.keyboardFocus: (scope.launcherOpen || (GlobalStates.mediaControlsOpen && scope.mode === "media")) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"
            mask: Region { item: container }

            anchors { top: true }
            margins { 
                top: (barIsPushing && barOnTop) ? -(Appearance.sizes.baseBarHeight + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)) : 0
            }

            HyprlandFocusGrab {
                windows: [win]
                active: scope.launcherOpen || (GlobalStates.mediaControlsOpen && scope.mode === "media")
                onCleared: {
                    if (!active) {
                        GlobalStates.overviewOpen = false;
                        GlobalStates.mediaControlsOpen = false;
                    }
                }
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (GlobalStates.overviewOpen) {
                        Qt.callLater(() => _launcherView.searchInput.forceActiveFocus());
                    }
                }
            }

            implicitWidth: Math.max(Constants.maxWidth, Constants.launcherWidth, Constants.overviewWidth) + 80
            implicitHeight: Math.max(Constants.expandedHeightHome,
                                     Constants.expandedHeightMedia,
                                     Constants.expandedHeightNotif,
                                     Constants.expandedHeightBattery,
                                     Constants.launcherMaxHeight,
                                     Constants.overviewHeight) + 80

            Item {
                id: container
                anchors.horizontalCenter: parent.horizontalCenter
                y: 0
                implicitWidth:  notch.implicitWidth
                implicitHeight: notch.implicitHeight
                focus: true

                readonly property bool islandVisible: (scope.mode !== "home" || GlobalStates.islandPinned) && !container.hideOnLockscreen && !container.fullscreenActive && GlobalStates.barOpen
                onIslandVisibleChanged: updateState()
                Component.onCompleted: updateState()
                
                function updateState() {
                    GlobalStates.registerIslandState(win.modelData.name, notch.bodyWidth, islandVisible);
                }
                
                Connections {
                    target: notch
                    function onBodyWidthChanged() { container.updateState() }
                }

                Keys.onPressed: event => {
                    if (scope.launcherOpen) {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.overviewOpen = false;
                            event.accepted = true;
                            return;
                        }

                        // Redirection for typing (when not focused)
                        if (!launcherView.searchInput.activeFocus) {
                            if (event.key === Qt.Key_Backspace) {
                                let text = LauncherSearch.query;
                                if (event.modifiers & Qt.ControlModifier) {
                                    let match = text.match(/(\s*\S+)\s*$/);
                                    let deleteLen = match ? match[0].length : 1;
                                    LauncherSearch.query = text.slice(0, Math.max(0, text.length - deleteLen));
                                } else {
                                    LauncherSearch.query = text.slice(0, Math.max(0, text.length - 1));
                                }
                                event.accepted = true;
                            } else if (event.text && event.text.length === 1 && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20) {
                                LauncherSearch.query += event.text;
                                event.accepted = true;
                                launcherView.focusFirstItem();
                            }
                        }
                    } else if (GlobalStates.mediaControlsOpen && pillState._displayMode === "media") {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.mediaControlsOpen = false;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Space) {
                            scope.player?.togglePlaying();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            scope.player?.previous();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            scope.player?.next();
                            event.accepted = true;
                        }
                    }
                }

                readonly property bool mediaPeekVisible:
                    pillState._displayMode === "media" && !pillState.expanded && scope.player !== null

                readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
                readonly property var monitorData: HyprlandData.monitors.find(m => m.name === monitor?.name)
                readonly property int activeWsId: (monitorData?.specialWorkspace?.id ?? 0) !== 0 ? monitorData.specialWorkspace.id : (monitorData?.activeWorkspace?.id ?? 0)
                readonly property bool fullscreenActive: HyprlandData.windowList.some(w =>
                    (w.fullscreen ?? 0) > 0 && w.workspace.id === activeWsId)

                readonly property bool hideOnLockscreen: Config.options.island.hideOnLockscreen && GlobalStates.screenLocked

                readonly property bool idleHidden: (pillState._displayMode === "home" && (!GlobalStates.islandPinned || container.fullscreenActive || !GlobalStates.barOpen || !win.barIsPushing)) || container.hideOnLockscreen

                opacity: idleHidden ? 0 : 1
                visible: opacity > 0.001

                Behavior on opacity {
                    NumberAnimation {
                        duration: (scope.mode !== "home" && pillState._displayMode === "home") ? 20 : Appearance.animation.elementMove.duration
                        easing.bezierCurve: Appearance.animationCurves.emphasized
                    }
                }

                transform: [
                    Scale {
                        id: containerScale
                        origin.x: container.width / 2
                        origin.y: 0
                        xScale: container.idleHidden ? 0.6 : 1
                        yScale: container.idleHidden ? 0.6 : 1
                        Behavior on xScale {
                            NumberAnimation {
                                duration: Appearance.animation.elementMove.duration
                                easing.bezierCurve: Appearance.animationCurves.emphasized
                            }
                        }
                        Behavior on yScale {
                            NumberAnimation {
                                duration: Appearance.animation.elementMove.duration
                                easing.bezierCurve: Appearance.animationCurves.emphasized
                            }
                        }
                    },
                    Translate {
                        id: containerTranslate
                        y: container.idleHidden ? -container.implicitHeight : 0
                        Behavior on y {
                            NumberAnimation {
                                duration: Appearance.animation.elementMove.duration
                                easing.bezierCurve: Appearance.animationCurves.emphasized
                            }
                        }
                    }
                ]

                QtObject {
                    id: pillState

                    property string _displayMode: scope.mode
                    property bool _modeStable: true

                    readonly property bool hoverable:
                        (_displayMode === "launcher" || _displayMode === "overview") ? false :
                        Constants.hoverIdleExpand
                            ? (_displayMode !== "osd")
                            : (_displayMode === "media" || _displayMode === "notif" || _displayMode === "battery")

                    readonly property bool expanded:
                        (_displayMode === "launcher" || _displayMode === "overview") ? true :
                        (hoverable && _modeStable && (hoverHandler.hovered || scope.peeking)) || (GlobalStates.mediaControlsOpen && _displayMode === "media")

                    readonly property int targetW: {
                        if (_displayMode === "launcher") {
                            return LauncherSearch.query === ""
                                ? Constants.launcherCollapsedWidth
                                : Constants.launcherWidth;
                        }
                        if (_displayMode === "overview") return Constants.overviewWidth;
                        if (expanded) {
                            switch (_displayMode) {
                                case "media":   return (card.showLyrics && scope.player !== null) ? 540 : Constants.expandedWidthMedia;
                                case "notif":   return Constants.expandedWidthNotif;
                                case "battery": return Constants.expandedWidthBattery;
                                case "home":    return Constants.expandedWidthHome;
                            }
                        }
                        switch (_displayMode) {
                            case "osd":     return Constants.compactWidthOsd;
                            case "notif":   return Constants.compactWidthNotif;
                            case "battery": return Constants.compactWidthBattery;
                            case "media":   return (scope.player !== null) ? Constants.compactWidthMedia : Constants.notchClosedWidth;
                            case "home":    return Constants.notchClosedWidth;
                        }
                        return Constants.notchClosedWidth;
                    }
                    readonly property int targetH: {
                        if (_displayMode === "launcher") {
                            return Math.max(Constants.launcherMinHeight,
                                            Math.min(Constants.launcherMaxHeight,
                                                     launcherView.desiredHeight));
                        }
                        if (_displayMode === "overview") return Constants.overviewHeight;
                        if (!expanded) {
                            if (_displayMode === "osd") return Constants.osdHeight;
                            return Constants.notchClosedHeight;
                        }
                        switch (_displayMode) {
                            case "media":   return (card.showLyrics && scope.player !== null) ? 260 : Constants.expandedHeightMedia;
                            case "notif":   return Constants.expandedHeightNotif;
                            case "battery": return Constants.expandedHeightBattery;
                            case "home":    return Constants.expandedHeightHome;
                        }
                        return Constants.notchClosedHeight;
                    }
                    readonly property real targetTopR:
                        (_displayMode === "launcher" || _displayMode === "overview") ? Constants.launcherTopRadius
                        : _displayMode === "osd" ? Constants.osdTopRadius
                        : expanded ? Constants.notchOpenTopRadius
                        : Constants.notchClosedTopRadius
                    readonly property real targetBottomR:
                        (_displayMode === "launcher" || _displayMode === "overview") ? Constants.launcherBottomRadius
                        : _displayMode === "osd" ? Constants.osdBottomRadius
                        : expanded ? Constants.notchOpenBottomRadius
                        : Constants.notchClosedBottomRadius
                }

                Connections {
                    target: scope
                    function onModeChanged() {
                        pillState._modeStable = false;
                        modeStableTimer.restart();
                    }
                }
                Timer {
                    id: modeStableTimer
                    interval: Constants.swapDurationMs
                    onTriggered: {
                        pillState._displayMode = scope.mode;
                        pillState._modeStable = true;
                    }
                }

                IslandShadow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    z: -1
                    bodyWidth: notch.bodyWidth
                    bodyHeight: notch.bodyHeight
                    topRadius: notch.topRadius
                    bottomRadius: notch.bottomRadius
                    tint: mediaExpanded.tintColor
                    tintAmount: pillState._displayMode === "media" ? 1 : 0
                    shadowOpacity: pillState.expanded ? 0.65 : 0.35
                }

                NotchShape {
                    id: notch
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    bodyWidth:    pillState.targetW
                    bodyHeight:   pillState.targetH
                    topRadius:    pillState.targetTopR
                    bottomRadius: pillState.targetBottomR
                    fillColor:    (pillState._displayMode === "media" && pillState.expanded)
                                      ? mediaExpanded.backdropColor
                                      : Appearance.colors.colLayer0
                    layer.enabled: true
                }

                HoverHandler { id: hoverHandler }

                MouseArea {
                    anchors.fill: notch
                    hoverEnabled: false
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    enabled: !(pillState._displayMode === "media" && pillState.expanded)
                              && pillState._displayMode !== "launcher"
                              && pillState._displayMode !== "overview"
                    onClicked: e => {
                        GlobalStates.superReleaseMightTrigger = false;
                        if (e.button === Qt.RightButton) {
                            const modes = ["none", "launcher", "osd", "battery", "notif", "media", "home"];
                            let idx = modes.indexOf(GlobalStates.islandDebugMode);
                            GlobalStates.islandDebugMode = modes[(idx + 1) % modes.length];
                        } else if (pillState._displayMode === "notif") {
                            GlobalStates.dashboardPanelOpen = true;
                        } else if (pillState._displayMode === "media" && scope.player) {
                            if (e.button === Qt.MiddleButton && scope.player.canGoNext) scope.player.next();
                            else if (scope.player.canTogglePlaying) scope.player.togglePlaying();
                        }
                    }
                }

                // OSD compact (volume/brightness/mic)
                IslandOsd {
                    id: islandOsd
                    anchors.fill: notch
                    anchors.leftMargin: notch.topRadius
                    anchors.rightMargin: notch.topRadius
                    mode: scope.osdMode
                    icon: scope.osdIcon
                    label: scope.osdLabel
                    value: scope.osdValue
                    from: scope.osdFrom
                    to: scope.osdTo
                    shape: scope.osdShape
                    protectionMessage: scope.osdProtectionMessage
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "osd" && pillState._displayMode === "osd"
                        PropertyChanges { target: islandOsd; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                IslandNotifCompact {
                    id: islandNotifCompact
                    anchors.fill: notch
                    anchors.leftMargin: notch.topRadius + 4
                    anchors.rightMargin: notch.topRadius + 4
                    notif: scope.topNotif
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "notif" && pillState._displayMode === "notif" && !pillState.expanded
                        PropertyChanges { target: islandNotifCompact; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                IslandNotifExpanded {
                    id: islandNotifExpanded
                    anchors.fill: notch
                    anchors.leftMargin: notch.topRadius
                    anchors.rightMargin: notch.topRadius
                    notif: scope.topNotif
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "notif" && pillState._displayMode === "notif" && pillState.expanded
                        PropertyChanges { target: islandNotifExpanded; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            SequentialAnimation {
                                PauseAnimation { duration: 100 }
                                NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                            }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                IslandBattery {
                    id: batteryView
                    anchors.fill: notch
                    anchors.leftMargin: notch.topRadius
                    anchors.rightMargin: notch.topRadius
                    expanded: pillState.expanded
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "battery" && pillState._displayMode === "battery"
                        PropertyChanges { target: batteryView; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                IslandOverview {
                    id: overviewView
                    anchors.fill: notch
                    anchors.margins: notch.topRadius
                    monitorIndex: container.monitor?.id ?? 0
                    panelWindow: win
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "overview" && pillState._displayMode === "overview"
                        PropertyChanges { target: overviewView; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                // Media expanded card
                Item {
                    id: mediaExpanded
                    anchors.fill: notch
                    readonly property bool shouldShow: pillState._displayMode === "media" && pillState.expanded
                    readonly property color tintColor: scope.player ? (card.blendedColors?.colPrimary ?? Appearance.m3colors.m3primary) : Appearance.m3colors.m3onSurface
                    readonly property color backdropColor: scope.player ? (card.blendedColors?.colLayer0 ?? Appearance.m3colors.m3surface) : Appearance.m3colors.m3surface
                    opacity: 0
                    visible: shouldShow || opacity > 0.001

                    states: State {
                        name: "visible"
                        when: mediaExpanded.shouldShow
                        PropertyChanges { target: mediaExpanded; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "visible"
                            SequentialAnimation {
                                PauseAnimation { duration: 100 }
                                NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                            }
                        },
                        Transition {
                            from: "visible"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]

                    IslandMediaCard {
                        id: card
                        anchors.fill: parent
                        radius: notch.bottomRadius
                        backdropMask: notch
                        contentSideInset: notch.topRadius
                    }
                }

                IslandMediaArtPeek {
                    id: artPeek
                    width: Constants.mediaArtPeekSize
                    height: Constants.mediaArtPeekSize
                    anchors.left: notch.left
                    anchors.leftMargin: notch.topRadius + Constants.mediaPeekGap
                    anchors.verticalCenter: notch.verticalCenter
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "media" && container.mediaPeekVisible && scope.player !== null
                        PropertyChanges { target: artPeek; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }
                
                IslandLauncher {
                    id: _launcherView
                    anchors.top: notch.top
                    anchors.left: notch.left
                    anchors.right: notch.right
                    anchors.bottom: notch.bottom
                    anchors.leftMargin: notch.topRadius
                    anchors.rightMargin: notch.topRadius
                    opacity: 0
                    visible: opacity > 0.001
                    onActivated: GlobalStates.overviewOpen = false
                    states: State {
                        name: "show"
                        when: scope.mode === "launcher" && pillState._displayMode === "launcher"
                        PropertyChanges { target: _launcherView; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.bezierCurve: Appearance.animationCurves.emphasized }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                IslandMediaVizPeek {
                    id: vizPeek
                    width: Constants.mediaVizPeekWidth
                    height: Constants.mediaArtPeekSize
                    anchors.right: notch.right
                    anchors.rightMargin: notch.topRadius + Constants.mediaPeekGap
                    anchors.verticalCenter: notch.verticalCenter
                    accentColor: mediaExpanded.tintColor
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "media" && container.mediaPeekVisible && scope.player !== null
                        PropertyChanges { target: vizPeek; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                IslandHomeCompact {
                    id: homeCompact
                    anchors.fill: notch
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "home" && pillState._displayMode === "home" && !pillState.expanded && GlobalStates.islandPinned
                        PropertyChanges { target: homeCompact; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }

                IslandHome {
                    id: homeExpanded
                    anchors.fill: notch
                    anchors.leftMargin: notch.topRadius
                    anchors.rightMargin: notch.topRadius
                    opacity: 0
                    visible: opacity > 0.001
                    states: State {
                        name: "show"
                        when: scope.mode === "home" && pillState._displayMode === "home" && pillState.expanded
                        PropertyChanges { target: homeExpanded; opacity: 1 }
                    }
                    transitions: [
                        Transition {
                            to: "show"
                            NumberAnimation { property: "opacity"; duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
                        },
                        Transition {
                            from: "show"
                            NumberAnimation { property: "opacity"; duration: 30; easing.type: Easing.OutCubic }
                        }
                    ]
                }
            }
        }
    }
}
