pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.bar.cards as BarCards

import "../background/widgets/clock" as ClockWidgets

Item {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool hasMedia: player !== null

    readonly property string clockStyle: Config.options.island.clock.style

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 24

        // Left Side: Time, Date & Media
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            Layout.preferredWidth: 160
            spacing: 0

            Item { Layout.fillHeight: true }

            Loader {
                id: clockLoader
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: root.clockStyle === "cookie" ? cookieComp : digitalComp

                Component {
                    id: digitalComp
                    ColumnLayout {
                        id: digitalClockRoot
                        spacing: 0
                        readonly property bool is12h: (Config.options.time?.format ?? "hh:mm").toLowerCase().includes("ap")
                        readonly property var timeParts: DateTime.time.split(" ")
                        
                        RowLayout {
                            spacing: 0
                            StyledText {
                                animateChange: Config.options.island?.clock?.digital?.animateChange ?? true
                                font.pixelSize: Config.options.island?.clock?.digital?.font?.size ?? 48
                                font.weight: Config.options.island?.clock?.digital?.font?.weight ?? 450
                                font.family: Config.options.island?.clock?.digital?.font?.family ?? Appearance.font.family.main
                                color: Config.options.island?.clock?.digital?.colorful ? Appearance.colors.colPrimary : Appearance.colors.colOnSecondaryContainer
                                text: (timeParts[0] ?? "00:00").split(":")[0].padStart(2, "0")
                                
                                font.variableAxes: ({
                                    "wdth": Config.options.island?.clock?.digital?.font?.width ?? 100,
                                    "ROND": Config.options.island?.clock?.digital?.font?.roundness ?? 0
                                })
                            }
                            
                            StyledText {
                                visible: Config.options.island?.clock?.digital?.showColon ?? true
                                animateChange: false
                                text: ":"
                                font.pixelSize: Config.options.island?.clock?.digital?.font?.size ?? 48
                                font.weight: Config.options.island?.clock?.digital?.font?.weight ?? 450
                                font.family: Config.options.island?.clock?.digital?.font?.family ?? Appearance.font.family.main
                                color: Config.options.island?.clock?.digital?.colorful ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondaryContainer
                                font.variableAxes: ({
                                    "wdth": Config.options.island?.clock?.digital?.font?.width ?? 100,
                                    "ROND": Config.options.island?.clock?.digital?.font?.roundness ?? 0
                                })
                            }

                            StyledText {
                                animateChange: Config.options.island?.clock?.digital?.animateChange ?? true
                                font.pixelSize: Config.options.island?.clock?.digital?.font?.size ?? 48
                                font.weight: Config.options.island?.clock?.digital?.font?.weight ?? 450
                                font.family: Config.options.island?.clock?.digital?.font?.family ?? Appearance.font.family.main
                                color: Config.options.island?.clock?.digital?.colorful ? Appearance.colors.colTertiary : Appearance.colors.colOnSecondaryContainer
                                text: (timeParts[0] ?? "00:00").split(":")[1] ?? "00"
                                font.variableAxes: ({
                                    "wdth": Config.options.island?.clock?.digital?.font?.width ?? 100,
                                    "ROND": Config.options.island?.clock?.digital?.font?.roundness ?? 0
                                })
                            }
                        }
                        
                        RowLayout {
                            Layout.topMargin: -8
                            spacing: 4
                            StyledText {
                                visible: Config.options.island?.clock?.digital?.showDate ?? true
                                color: Appearance.colors.colOnSecondaryContainer
                                opacity: 0.65
                                text: DateTime.longDate
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            StyledText {
                                visible: digitalClockRoot.is12h && timeParts.length > 1
                                color: Appearance.colors.colPrimary
                                opacity: 0.8
                                text: timeParts[1] ?? ""
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                Component {
                    id: cookieComp
                    Item {
                        implicitWidth: 160
                        implicitHeight: 110
                        ClockWidgets.CookieClock {
                            anchors.centerIn: parent
                            implicitSize: 110
                            options: Config.options.island?.clock?.cookie ?? Config.options.background.widgets.clock.cookie
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Media Info (if playing)
            RowLayout {
                visible: root.hasMedia
                spacing: 8
                Layout.topMargin: 4
                Layout.fillWidth: true

                MaterialSymbol {
                    text: root.player?.playbackState === MprisPlaybackState.Playing ? "music_note" : "pause"
                    fill: 1
                    iconSize: 14
                    color: Appearance.m3colors.m3primary
                }
                StyledText {
                    color: Appearance.m3colors.m3onSurface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    text: {
                        const t = root.player?.trackTitle ?? "";
                        const a = root.player?.trackArtist ?? "";
                        return a ? `${t} — ${a}` : t;
                    }
                    font.pixelSize: Appearance.font.pixelSize.smallest
                }
            }
        }

        // Right Side: Advanced Resource Cards (Simplified)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                BarCards.ResourceCard {
                    title: Translation.tr("RAM")
                    icon: "memory"
                    shapeString: "Clover4Leaf"
                    shapeColor: Appearance.colors.colSecondaryContainer
                    symbolColor: Appearance.colors.colOnSecondaryContainer
                    margins: 8
                    spacing: 4
                    shapeSize: 22
                    titleFontSize: Appearance.font.pixelSize.normal

                    resourceName: Translation.tr("Used")
                    resourceNameFontSize: Appearance.font.pixelSize.smaller
                    resourceValueText: `${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
                    resourceValueFontSize: Appearance.font.pixelSize.smallie
                    resourcePercentage: ResourceUsage.memoryUsedPercentage
                    highlightColor: Appearance.colors.colSecondary
                }

                BarCards.ResourceCard {
                    title: Translation.tr("CPU")
                    icon: "planner_review"
                    shapeString: "Gem"
                    shapeColor: Appearance.colors.colTertiaryContainer
                    symbolColor: Appearance.colors.colOnTertiaryContainer
                    margins: 8
                    spacing: 4
                    shapeSize: 22
                    titleFontSize: Appearance.font.pixelSize.normal

                    resourceName: Translation.tr("Load")
                    resourceNameFontSize: Appearance.font.pixelSize.smaller
                    resourceValueText: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                    resourceValueFontSize: Appearance.font.pixelSize.smallie
                    resourcePercentage: ResourceUsage.cpuUsage
                    highlightColor: Appearance.colors.colTertiary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                BarCards.ResourceCard {
                    title: Translation.tr("Swap")
                    icon: "swap_horiz"
                    shapeString: "Bun"
                    shapeColor: Appearance.colors.colPrimaryContainer
                    symbolColor: Appearance.colors.colOnPrimaryContainer
                    margins: 8
                    spacing: 4
                    shapeSize: 22
                    titleFontSize: Appearance.font.pixelSize.normal

                    resourceName: Translation.tr("Used")
                    resourceNameFontSize: Appearance.font.pixelSize.smaller
                    resourceValueText: `${Math.round(ResourceUsage.swapUsedPercentage * 100)}%`
                    resourceValueFontSize: Appearance.font.pixelSize.smallie
                    resourcePercentage: ResourceUsage.swapUsedPercentage
                    highlightColor: Appearance.colors.colPrimary
                }

                BarCards.ResourceCard {
                    title: Translation.tr("Disk")
                    icon: "hard_drive"
                    shapeString: "Circle"
                    shapeColor: Appearance.colors.colSecondaryContainer
                    symbolColor: Appearance.colors.colOnSecondaryContainer
                    margins: 8
                    spacing: 4
                    shapeSize: 22
                    titleFontSize: Appearance.font.pixelSize.normal

                    resourceName: Translation.tr("Storage")
                    resourceNameFontSize: Appearance.font.pixelSize.smaller
                    resourceValueText: `${Math.round(ResourceUsage.diskUsedPercentage * 100)}%`
                    resourceValueFontSize: Appearance.font.pixelSize.smallie
                    resourcePercentage: ResourceUsage.diskUsedPercentage
                    highlightColor: Appearance.colors.colSecondary
                }
            }
            
            // Minimal Battery at the far right
            IslandBatteryIcon {
                size: 16
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: 8
            }
        }
    }
}
