pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.ii.island

Item {
    id: root

    readonly property string searchingText: LauncherSearch.query
    readonly property bool showResults: searchingText != ""
    readonly property bool queryEmpty: searchingText === ""

    property alias listView: listView
    property alias searchInput: searchBar.searchInput

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                const prefixes = [
                    Config.options.search.prefix.action,
                    Config.options.search.prefix.app,
                    Config.options.search.prefix.clipboard,
                    Config.options.search.prefix.emojis,
                    Config.options.search.prefix.math,
                    Config.options.search.prefix.shellCommand,
                    Config.options.search.prefix.webSearch
                ];
                
                const hasPrefix = prefixes.some(p => LauncherSearch.query.startsWith(p));
                
                if (hasPrefix) {
                    searchBar.searchInput.text = LauncherSearch.query;
                } else {
                    root.clear();
                }
                
                Qt.callLater(() => root.focusSearchInput());
            } else {
                root.clear();
            }
        }
    }

    function focusFirstItem() {
        listView.currentIndex = 0;
    }

    function focusSearchInput() {
        searchBar.forceFocus();
    }

    // Mirrored results for smoother animation when clearing search
    property var displayedResults: []
    
    Timer {
        id: debounceTimer
        interval: 150
        onTriggered: {
            if (LauncherSearch.query !== "") {
                root.displayedResults = LauncherSearch.results.slice(0, 15);
                root.focusFirstItem();
            }
        }
    }

    Connections {
        target: LauncherSearch
        function onResultsChanged() {
            if (LauncherSearch.query !== "") {
                clearTimer.stop();
                debounceTimer.restart();
            } else {
                clearTimer.restart();
                debounceTimer.stop();
            }
        }
    }
    Timer {
        id: clearTimer
        interval: Appearance.animation.elementMove.duration
        onTriggered: root.displayedResults = []
    }

    // Target height for parent (Island) to drive notch animation.
    readonly property real desiredHeight: {
        const head = searchBar.implicitHeight;
        if (!showResults) return head + 12; // Significantly longer toward the bottom as requested
        const listMax = Constants.launcherMaxHeight - head;
        const listH = Math.min(listMax, listView.contentHeight + 8);
        return head + Math.max(0, listH);
    }

    signal activated

    function clear()       { searchBar.searchInput.text = ""; LauncherSearch.query = ""; }
    
    function activateCurrent() {
        const cur = listView.currentItem;
        if (cur && cur.entry) {
            cur.entry.execute();
            root.activated();
        }
    }

    // Keyboard logic for redirection (when TextField is not focused)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape)
            return;

        if (event.key === Qt.Key_Backspace) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                let text = LauncherSearch.query;
                if (event.modifiers & Qt.ControlModifier) {
                    let match = text.match(/(\s*\S+)\s*$/);
                    let deleteLen = match ? match[0].length : 1;
                    LauncherSearch.query = text.slice(0, Math.max(0, text.length - deleteLen));
                } else {
                    LauncherSearch.query = text.slice(0, Math.max(0, text.length - 1));
                }
                event.accepted = true;
            }
            return;
        }

        if (event.text && event.text.length === 1 && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20)
        {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                LauncherSearch.query += event.text;
                event.accepted = true;
                root.focusFirstItem();
            }
        }
    }

    implicitHeight: column.height
    implicitWidth: column.width
    clip: true

    Column {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        IslandSearchBar {
            id: searchBar
            width: parent.width
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            searchingText: root.searchingText
            resultView: listView
            onActivated: root.activated()
        }

        Rectangle {
            // Separator
            visible: root.showResults && listView.count > 0
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            height: 1
            color: Appearance.colors.colOutlineVariant
        }

        ListView {
            id: listView
            width: parent.width
            height: Math.min(Constants.launcherMaxHeight - searchBar.height, contentHeight + 8)
            visible: count > 0 && root.showResults
            clip: true
            topMargin: 0
            bottomMargin: 8
            spacing: 1
            highlightMoveDuration: 100
            keyNavigationEnabled: true
            interactive: true

            KeyNavigation.up: searchBar

            onFocusChanged: {
                if (focus && count > 1)
                    currentIndex = 1;
            }

            model: ScriptModel {
                id: resultModel
                objectProp: "key"
                values: root.displayedResults
            }

            delegate: IslandSearchItem {
                required property var modelData
                width: ListView.view.width
                height: implicitHeight
                entry: modelData
                query: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])
                selected: ListView.isCurrentItem
                onClicked: {
                    modelData.execute();
                    root.activated();
                }
                onActionExecuted: actionName => {
                    if (actionName !== Translation.tr("Delete")) {
                        root.activated();
                    }
                }
            }
        }
    }
}
