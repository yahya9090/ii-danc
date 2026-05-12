import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root

    property alias sidebarLeftOpen: root.policiesPanelOpen // Until all sidebars naming is fixed
    property alias sidebarRightOpen: root.dashboardPanelOpen // Until all sidebars naming is fixed

    property bool barOpen: true
    property bool crosshairOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool workspacesOverviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool screenTranslatorOpen: false
    property bool islandPinned: true
    Binding {
        target: root
        property: "islandPinned"
        value: Config.ready ? Config.options.island.pinned : true
        when: Config.ready
    }
    onIslandPinnedChanged: {
        if (Config.ready && Config.options.island.pinned !== islandPinned) {
            Config.options.island.pinned = islandPinned;
        }
    }
    property string islandDebugMode: "none"
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool dontAutoCancelSearch: false
    property bool settingsOpen: false
    property string settingsPage: ""
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false

    property var mediaPositions: ({})

    property var islandStates: ({})
    function registerIslandState(monitorName, width, visible) {
        let states = root.islandStates;
        states[monitorName] = { "width": width, "visible": visible };
        root.islandStates = Object.assign({}, states);
    }

    property var barPushingStates: ({})
    function registerBarPushingState(monitorName, pushing) {
        let states = root.barPushingStates;
        states[monitorName] = pushing;
        root.barPushingStates = Object.assign({}, states);
    }

    function toggleClipboard() {
        if (root.overviewOpen && root.dontAutoCancelSearch) {
            root.overviewOpen = false;
            return;
        }
        root.dontAutoCancelSearch = true;
        LauncherSearch.query = Config.options.search.prefix.clipboard;
        root.overviewOpen = true;
    }

    function toggleEmojis() {
        if (root.overviewOpen && root.dontAutoCancelSearch) {
            root.overviewOpen = false;
            return;
        }
        root.dontAutoCancelSearch = true;
        LauncherSearch.query = Config.options.search.prefix.emojis;
        root.overviewOpen = true;
    }

    function toggleSymbols() {
        if (root.overviewOpen && root.dontAutoCancelSearch) {
            root.overviewOpen = false;
            return;
        }
        root.dontAutoCancelSearch = true;
        LauncherSearch.query = Config.options.search.prefix.symbols;
        root.overviewOpen = true;
    }

    function registerMediaPosition(monitorName, x, y, width, height) {
        let positions = root.mediaPositions;
        positions[monitorName] = { "x": x, "y": y, "width": width, "height": height };
        root.mediaPositions = Object.assign({}, positions);
    }

    signal colorPickerLaunchRequested()

    // Bluetooth connection popup
    property bool bluetoothConnectionPopupOpen: false
    property var bluetoothConnectionPopupDevice: null

    // Color Picker Popup
    property bool colorPickerPopupOpen: false
    property string colorPickerPopupColor: ""

    function pickColor(hex) {
        if (hex && hex.startsWith("#")) {
            root.colorPickerPopupColor = hex;
            root.colorPickerPopupOpen = false;
            Qt.callLater(() => {
                root.colorPickerPopupOpen = true;
            });
        }
    }

    function launchColorPicker() {
        root.colorPickerLaunchRequested();
    }

    signal mediaControlsToggleRequested()

    IpcHandler {
        target: "pickColor"
        function handle(hex: string): void {
            root.pickColor(hex);
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.overviewOpen = !root.overviewOpen;
        }
        function workspacesToggle() {
            root.workspacesOverviewOpen = !root.workspacesOverviewOpen;
        }
        function close() {
            root.overviewOpen = false;
            root.workspacesOverviewOpen = false;
        }
        function open() {
            root.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            root.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            root.toggleClipboard();
        }
        function symbolsToggle() {
            root.toggleSymbols();
        }
        function emojisToggle() {
            root.toggleEmojis();
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"
        onPressed: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
    }
    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"
        onPressed: {
            GlobalStates.overviewOpen = false
            GlobalStates.workspacesOverviewOpen = false
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"
        onPressed: GlobalStates.workspacesOverviewOpen = !GlobalStates.workspacesOverviewOpen
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release of Super"

        onPressed: {
            // Only set to true on the initial press to avoid repeated keys resetting it
            if (!root.superDown) {
                root.superReleaseMightTrigger = true;
            }
            root.superDown = true;
        }

        onReleased: {
            root.superDown = false;
            if (!root.superReleaseMightTrigger) {
                root.superReleaseMightTrigger = true;
                return;
            }
            root.overviewOpen = !root.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts search on release"

        onPressed: {
            root.superReleaseMightTrigger = false;
        }
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            root.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            root.toggleEmojis();
        }
    }

    GlobalShortcut {
        name: "overviewSymbolsToggle"
        description: "Toggle material symbols search on overview widget"

        onPressed: {
            root.toggleSymbols();
        }
    }

    property bool dashboardPanelOpen: false // formerly sidebarRightOpen
    property bool policiesPanelOpen: false  // formerly sidebarLeftOpen

    readonly property bool effectiveLeftOpen: {
        switch (Config.options.sidebar.position) {
            case "default":  return policiesPanelOpen;  
            case "inverted": return dashboardPanelOpen;  
            case "left":     return dashboardPanelOpen || policiesPanelOpen;
            case "right":    return false;
            default:         return policiesPanelOpen;
        }
    }
    readonly property bool effectiveRightOpen: {
        switch (Config.options.sidebar.position) {
            case "default":  return dashboardPanelOpen; 
            case "inverted": return policiesPanelOpen; 
            case "left":     return false;
            case "right":    return dashboardPanelOpen || policiesPanelOpen;
            default:         return dashboardPanelOpen;
        }
    }

    onPoliciesPanelOpenChanged: {
        if (policiesPanelOpen) {
            if (Config.options.sidebar.position == "right" || Config.options.sidebar.position == "left") {
                GlobalStates.dashboardPanelOpen = false
            }
        }
        
    }

    onDashboardPanelOpenChanged: {
        if (dashboardPanelOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
            if (Config.options.sidebar.position == "right" || Config.options.sidebar.position == "left") {
                GlobalStates.policiesPanelOpen = false
            }
        }
        
    }
    
    onOverviewOpenChanged: {
        if (!root.overviewOpen) {
            root.dontAutoCancelSearch = false;
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"
        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}
