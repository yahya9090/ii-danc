import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope

    signal setSearchingTextRequested(string text)

    Variants {
        id: overviewVariant

        property var variantModel: Quickshell.screens

        model: overviewVariant.variantModel

        LazyLoader {
            id: realOverviewLoader
            required property var modelData
            property int monitorIndex: overviewVariant.variantModel.indexOf(modelData)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitorIndex)
            
            // Disable full-screen overview when islands are enabled to avoid overlap.
            // IPC and shortcuts are now handled in GlobalStates.qml.
            active: (monitorIsFocused || isOpen) && !Config.options.island.enable

            property bool isOpen: GlobalStates.overviewOpen || GlobalStates.workspacesOverviewOpen

            component: PanelWindow {
                id: root

                readonly property bool monitorIsFocused: realOverviewLoader.monitorIsFocused
                readonly property int monitorIndex: realOverviewLoader.monitorIndex
                readonly property bool isOpen: GlobalStates.overviewOpen || GlobalStates.workspacesOverviewOpen

                readonly property bool isScrollingLayout: Persistent.states.hyprland.layout === "scrolling"
                property string searchingText: ""

                WlrLayershell.namespace: "quickshell:overview"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: root.isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
                color: "transparent"

                property var zoomLevels: {  // has to be reverted compared to background
                    "in": { default: 1, zoomed: 1.04 },
                    "out": { default: 1.04, zoomed: 1 }
                }

                readonly property bool isZoomInStyle: Config.options.overview.scrollingStyle.zoomStyle === "in"
                readonly property bool showOpeningAnimation: Config.options.overview.showOpeningAnimation

                property real defaultRatio: isZoomInStyle ? zoomLevels.in.default : zoomLevels.out.default
                property real zoomedRatio: isZoomInStyle ? zoomLevels.in.zoomed : zoomLevels.out.zoomed

                property bool isResettingZoom: false 
                property real scaleAnimated: showOpeningAnimation ? root.isOpen ? zoomedRatio : defaultRatio : 1

                property real effectiveScale: showOpeningAnimation ? zoomedRatio - scaleAnimated + 1 : 1 

                onIsZoomInStyleChanged: isResettingZoom = true
                onScaleAnimatedChanged: {
                    if (scaleAnimated === defaultRatio) {
                        isResettingZoom = false
                    }
                }

                visible: {
                    if (isResettingZoom) return false;
                    if (!showOpeningAnimation) return root.isOpen;
                    
                    const isVisible = isZoomInStyle ? scaleAnimated > defaultRatio : scaleAnimated < defaultRatio;
                    return isVisible || root.isOpen;
                }

                Behavior on scaleAnimated {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root)
                }

                anchors {
                    top: true; bottom: true; left: true; right: true
                }
                property int barSize: Config.options.bar.vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
                property int margin: isZoomInStyle ? barSize : barSize * 2
                margins { 
                    top: -margin * 2; bottom: -margin * 2; left: -margin * 2; right: -margin * 2
                }

                HyprlandFocusGrab {
                    id: grab
                    windows: [root]
                    property bool canBeActive: root.isOpen && root.monitorIsFocused
                    active: false
                    onCleared: () => {
                        if (!active) {
                            GlobalStates.overviewOpen = false;
                            GlobalStates.workspacesOverviewOpen = false;
                        }
                    }
                }

                Connections {
                    target: GlobalStates
                    function onOverviewOpenChanged() {
                        handleStateChange();
                    }
                    function onWorkspacesOverviewOpenChanged() {
                        handleStateChange();
                    }
                }

                function handleStateChange() {
                    if (!root.isOpen) {
                        searchWidget.disableExpandAnimation();
                    } else {
                        if (!GlobalStates.dontAutoCancelSearch) {
                            searchWidget.cancelSearch();
                        }
                        delayedGrabTimer.start();
                    }
                }

                Timer {
                    id: delayedGrabTimer
                    interval: Config.options.hacks.arbitraryRaceConditionDelay
                    repeat: false
                    onTriggered: {
                        if (!grab.canBeActive)
                            return;
                        grab.active = root.isOpen;
                    }
                }

                Connections {
                    target: overviewScope
                    function onSetSearchingTextRequested(text) {
                        root.setSearchingText(text);
                    }
                }


                function setSearchingText(text) {
                    searchWidget.setSearchingText(text);
                    searchWidget.focusFirstItem();
                }

                Item {
                    id: contentItem
                    anchors.fill: parent

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.overviewOpen = false;
                            GlobalStates.workspacesOverviewOpen = false;
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            GlobalStates.overviewOpen = false;
                            GlobalStates.workspacesOverviewOpen = false;
                        }
                    }

                    Item { 
                        id: searchWidgetWrapper
                        implicitHeight: searchWidget.implicitHeight
                        implicitWidth: searchWidget.implicitWidth
                        z: 999

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                GlobalStates.overviewOpen = false;
                                GlobalStates.workspacesOverviewOpen = false;
                            }
                        }

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: parent.top
                            topMargin: root.margin * 2 + Appearance.sizes.elevationMargin
                        }
                        SearchWidget {
                            id: searchWidget
                            scale: root.effectiveScale
                            anchors.horizontalCenter: parent.horizontalCenter
                            Synchronizer on searchingText {
                                property alias source: root.searchingText
                            }
                        }
                    }
                    

                    Loader { // Classic overview
                        id: overviewLoader
                        scale: root.effectiveScale
                        anchors.top: searchWidgetWrapper.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        active: root.isOpen && !root.isScrollingLayout
                        sourceComponent: OverviewWidget {
                            panelWindow: root
                            visible: (root.searchingText == "")
                            monitorIndex: root.monitorIndex
                        }
                    }

                    Loader { // Scrolling overview
                        id: scrollingOverviewLoader
                        scale: root.effectiveScale
                        anchors.fill: parent
                        active: root.isOpen && root.isScrollingLayout
                        sourceComponent: ScrollingOverviewWidget {
                            anchors.fill: parent
                            panelWindow: root
                            visible: (root.searchingText == "")
                            monitorIndex: root.monitorIndex
                        }
                    }
                }   
            }   
        }
    }
}
