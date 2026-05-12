import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF

Scope {
    id: root

    LazyLoader {
        id: settingsLoader
        active: GlobalStates.settingsOpen

        component: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
            property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)

            WlrLayershell.namespace: "quickshell:settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true; bottom: true; left: true; right: true
            }

            // Simple background to dismiss
            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.settingsOpen = false
            }

            // Settings content card
            Rectangle {
                anchors.centerIn: parent
                width: 900
                height: 650
                radius: Appearance.rounding.large
                color: Appearance.m3colors.m3background
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                // Prevent click propagation to background dismiss
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                // Header / Sidebar logic from settings.qml
                // (Simplified for now to fix crash and provide base functionality)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("Settings")
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                        }
                        Item { Layout.fillWidth: true }
                        RippleButton {
                            buttonRadius: 999
                            implicitWidth: 40
                            implicitHeight: 40
                            onClicked: GlobalStates.settingsOpen = false
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Appearance.colors.colLayer0Border
                    }

                    StyledText {
                        text: Translation.tr("Settings integration is partially implemented. Use Super+I for the full settings app.")
                        color: Appearance.colors.colSubtext
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    Item { Layout.fillHeight: true }
                }
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
                    GlobalStates.settingsOpen = false;
                }
            }
        }
    }
}
