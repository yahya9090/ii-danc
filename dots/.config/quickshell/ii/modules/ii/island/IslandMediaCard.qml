pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtCore
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.ii.island
import qs.services

// Expanded media card for the island. Targets ~440x112. Art-themed surface via
// MediaArtBackdrop + AdaptedMaterialScheme.
Item {
    id: root

    property MprisPlayer player: MprisController.activePlayer
    property real radius: Constants.expandRadius
    property Item backdropMask: null
    property real contentSideInset: 0

    readonly property string artUrl: (player?.trackArtUrl ?? "").toString()
    readonly property string artDownloadLocation: Directories.coverArt
    readonly property string artFileName: artUrl ? Qt.md5(artUrl) : ""
    readonly property string artFilePath: artFileName ? `${artDownloadLocation}/${artFileName}` : ""
    property bool downloaded: false
    property color artDominantColor: ColorUtils.mix((colorQuantizer?.colors[0] ?? Appearance.colors.colPrimary), Appearance.colors.colPrimaryContainer, 0.8)

    readonly property bool browserPlayer:      (player?.dbusName ?? "").includes("firefox") || (player?.dbusName ?? "").includes("chromium")
    readonly property string playerctlName:    player?.dbusName ?? ""
    readonly property bool artIsRemote:        artUrl.startsWith("http")
    readonly property string immediateArtSource: !artIsRemote ? artUrl : ""

    readonly property string displayedArtFilePath: {
        if (artUrl.length === 0) return "";
        if (immediateArtSource.length > 0) return immediateArtSource;
        if (artIsRemote && downloaded) return Qt.resolvedUrl(artFilePath);
        return "";
    }

    readonly property real displayedPosition:
        browserPlayer ? browserPoller.position : StringUtils.normalizeTime(player?.position ?? 0)
    readonly property bool progressAnimating:
        browserPlayer ? browserPoller.animating : (player?.playbackState === MprisPlaybackState.Playing)
    readonly property real lengthSec: {
        const pollerLen = browserPoller.length;
        if (browserPlayer && pollerLen > 0) return pollerLen;
        return StringUtils.normalizeTime(player?.length ?? 0);
    }
    readonly property real progressFrac: lengthSec > 0 ? Math.max(0, Math.min(1, displayedPosition / lengthSec)) : 0

    property bool showLyrics: false

    property QtObject blendedColors: AdaptedMaterialScheme { color: root.artDominantColor }

    onPlayerChanged: browserPoller.reset()

    onArtUrlChanged: {
        coverArtDownloader.running = false;
        if (artUrl.length === 0) { downloaded = false; return; }
        if (immediateArtSource.length > 0) { downloaded = true; return; }
        coverArtDownloader.targetFile = artUrl;
        coverArtDownloader.artFilePath = artFilePath;
        downloaded = false;
        coverArtDownloader.running = true;
    }

    Timer {
        running: !root.browserPlayer && root.player?.playbackState === MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: { if (root.player) root.player.positionChanged() }
    }

    MediaBrowserPoller {
        id: browserPoller
        playerName: root.playerctlName
        active: root.browserPlayer && root.visible
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl ?? ""
        property string artFilePath: root.artFilePath
        command: [
            "bash", "-c",
            `mkdir -p ${root.artDownloadLocation} && `
            + `{ [ -s ${artFilePath} ] || `
            + `curl -L --fail -sS '${targetFile}' -o ${artFilePath}; }`
        ]
        onExited: exitCode => root.downloaded = exitCode === 0
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    MediaArtBackdrop {
        anchors.fill: parent
        radius: root.radius
        artSource: root.displayedArtFilePath
        colors: root.blendedColors
        showShadow: false
        maskSource: root.backdropMask

        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: root.showLyrics ? lyricsComponent : infoComponent

            Component {
                id: infoComponent
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14 + root.contentSideInset
                    anchors.rightMargin: 14 + root.contentSideInset
                    anchors.topMargin: 12
                    anchors.bottomMargin: 12
                    spacing: 14

                    // ── Art tile ─────────────────────────────────────────────────
                    Rectangle {
                        id: artTile
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 80
                        Layout.alignment: Qt.AlignVCenter
                        radius: 16
                        color: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.4)
                        antialiasing: true

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artTile.width
                                height: artTile.height
                                radius: artTile.radius
                            }
                        }

                        Image {
                            anchors.fill: parent
                            source: root.displayedArtFilePath
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            asynchronous: true
                            antialiasing: true
                            sourceSize.width: 256
                            sourceSize.height: 256
                            visible: opacity > 0
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic } }
                        }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: root.displayedArtFilePath.length === 0
                            text: "music_note"
                            fill: 1
                            iconSize: 28
                            color: root.blendedColors.colSubtext
                        }
                    }

                    // ── Right column ─────────────────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 0

                        MarqueeText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            text: root.player ? (root.player.trackTitle || "Untitled") : Translation.tr("No active player")
                            textColor: root.blendedColors.colOnLayer0
                            fontFamily: Appearance.font.family.main
                            fontSize: Appearance.font.pixelSize.large
                            fontWeight: Font.DemiBold
                            pixelsPerSecond: 35
                        }

                        StyledText {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16
                            text: root.player ? (root.player.trackArtist || "") : Translation.tr("Open a player with MPRIS support")
                            color: root.blendedColors.colSubtext
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.small
                        }

                        Item { Layout.fillHeight: true }

                        MediaControls {
                            Layout.fillWidth: true
                            player: root.player
                            colors: root.blendedColors
                            position: root.displayedPosition
                            length: root.lengthSec
                            opacity: root.player ? 1 : 0
                            visible: opacity > 0
                            onLyricsRequested: root.showLyrics = true
                            Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }

                            MediaProgress {
                                anchors.fill: parent
                                player: root.player
                                position: root.displayedPosition
                                length: root.lengthSec
                                animating: root.progressAnimating
                                browserPlayer: root.browserPlayer
                                colors: root.blendedColors
                                onSeekRequested: pos => {
                                    if (!root.player) return;
                                    root.player.position = pos * 1000000;
                                    if (root.browserPlayer) browserPoller.syncPosition(pos);
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: !root.player
                            spacing: 8
                            
                            MaterialSymbol {
                                text: "info"
                                iconSize: 14
                                color: root.blendedColors.colSubtext
                            }
                            StyledText {
                                text: Translation.tr("Try starting some music or video")
                                color: root.blendedColors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                opacity: 0.8
                            }
                        }
                    }
                }
            }

            Component {
                id: lyricsComponent
                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15 + root.contentSideInset
                    anchors.rightMargin: 15 + root.contentSideInset
                    anchors.topMargin: 15
                    anchors.bottomMargin: 15
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 15

                        Rectangle {
                            id: artTileLyrics
                            Layout.preferredHeight: 130
                            Layout.preferredWidth: 130
                            radius: 16
                            color: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.4)

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: artTileLyrics.width
                                    height: artTileLyrics.height
                                    radius: artTileLyrics.radius
                                }
                            }

                            Image {
                                anchors.fill: parent
                                source: root.displayedArtFilePath
                                fillMode: Image.PreserveAspectCrop
                                cache: false
                                antialiasing: true
                            }
                        }

                        Item {
                            id: interactiveLyricsItem
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            readonly property bool hasSyncedLines: LyricsService.hasSyncedLines

                            Component.onCompleted: LyricsService.initiliazeLyrics()

                            FadeLoader {
                                shown: !interactiveLyricsItem.hasSyncedLines
                                anchors.fill: parent
                                sourceComponent: LyricsFlickable {
                                    anchors.fill: parent
                                    player: root.player
                                    fontPixelSize: 14
                                    textColor: root.blendedColors.colOnLayer0
                                    loadingIndicatorSize: 64
                                    indicatorColor: ColorUtils.applyAlpha(root.blendedColors.colPrimary, 0.2)
                                    shapeColor: root.blendedColors.colPrimary
                                }
                            }
                            
                            FadeLoader {
                                shown: interactiveLyricsItem.hasSyncedLines
                                anchors.fill: parent
                                sourceComponent: LyricsSyllable {
                                    anchors.fill: parent
                                    largeFontSize: 18
                                    activeColor: root.blendedColors.colPrimary
                                    preferredHighlightBegin: parent.height / 2 - 20
                                    preferredHighlightEnd: parent.height / 2
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        spacing: 15

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0
                            StyledText {
                                text: root.player?.trackTitle || "Untitled"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Bold
                                color: root.blendedColors.colOnLayer0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: root.player?.trackArtist || ""
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: root.blendedColors.colSubtext
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MediaControls {
                            Layout.preferredWidth: 240
                            Layout.alignment: Qt.AlignBottom
                            player: root.player
                            colors: root.blendedColors
                            position: root.displayedPosition
                            length: root.lengthSec
                            onLyricsRequested: root.showLyrics = false

                            MediaProgress {
                                anchors.fill: parent
                                player: root.player
                                position: root.displayedPosition
                                length: root.lengthSec
                                animating: root.progressAnimating
                                browserPlayer: root.browserPlayer
                                colors: root.blendedColors
                                onSeekRequested: pos => {
                                    if (!root.player) return;
                                    root.player.position = pos * 1000000;
                                    if (root.browserPlayer) browserPoller.syncPosition(pos);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
