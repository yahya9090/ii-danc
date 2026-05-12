pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root
    property var player: Mpris.players.values.length > 0 ? (Mpris.players.values[playerSelector.currentIndex] ?? Mpris.players.values[0]) : null
    property var artUrl: player?.trackArtUrl ?? ""
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: (artUrl && artUrl !== "") ? Qt.md5(artUrl) : ""
    property string artFilePath: artFileName !== "" ? `${artDownloadLocation}/${artFileName}` : ""
    property color artDominantColor: {
        const secondary = (Appearance && Appearance.colors) ? Appearance.colors.colPrimary : (Appearance && Appearance.m3colors) ? Appearance.m3colors.m3secondaryContainer : "#cccccc"
        if (!root.artUrl || root.artUrl.length == 0) {
            return secondary
        }
        const primary = (Appearance && Appearance.colors) ? Appearance.colors.colPrimary : "#ffffff"
        const container = (Appearance && Appearance.colors) ? Appearance.colors.colPrimaryContainer : "#eeeeee"
        return ColorUtils.mix((colorQuantizer?.colors[0] ?? primary), container, 0.8) || secondary
    }
    property bool downloaded: false
    property real radius

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    onArtFilePathChanged: {
        if (!root.artUrl || root.artUrl.length == 0) {
            return
        }
        coverArtDownloader.targetFile = root.artUrl
        coverArtDownloader.artFilePath = root.artFilePath
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process {
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: ["bash", "-c", `[ -f ${artFilePath} ] || curl -sSL '${targetFile}' -o '${artFilePath}'`]
        onExited: (exitCode, exitStatus) => { root.downloaded = true }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: artDominantColor
    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: -1
        anchors.bottomMargin: 4
        color: Appearance.colors.colLayer2
        radius: (Appearance && Appearance.rounding) ? Appearance.rounding.normal : 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: parent.height * 0.04
            spacing: 0

            // ── Player selector ──
            StyledComboBox {
                id: playerSelector
                visible: Mpris.players.values.length > 1
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                model: Mpris.players.values.map(p => p.identity ?? p.desktopEntry ?? "Unknown")
                currentIndex: 0
            }

            // ── Album art ──
            Rectangle {
                id: artBackground
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(parent.width * 1, parent.height * 0.45)
                Layout.preferredHeight: Layout.preferredWidth
                radius: (Appearance && Appearance.rounding) ? Appearance.rounding.small : 0
                color: ColorUtils.transparentize(blendedColors.colLayer1, 0.5)

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: artBackground.width
                        height: artBackground.height
                        radius: artBackground.radius
                    }
                }

                StyledImage {
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    sourceSize.width: artBackground.width
                    sourceSize.height: artBackground.height
                }
            }

            // ── Title & Artist ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: parent.height * 0.025
                Layout.bottomMargin: parent.height * 0.02
                spacing: parent.height * 0.005

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: titleText.implicitHeight
                    Layout.minimumHeight: Math.max(16, parent.parent.height * 0.024) * 1.5
                    clip: true

                    StyledText {
                        id: titleText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        font.pixelSize: Math.max(16, parent.parent.height * 0.024)
                        font.weight: Font.Bold
                        color: blendedColors.colOnLayer0
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: titleText; property: "x"; to: -titleText.width; duration: 150; easing.type: Easing.InQuad }
                                PropertyAction { target: titleText; property: "text" }
                                NumberAnimation { target: titleText; property: "x"; from: titleText.width; to: 0; duration: 150; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: artistText.implicitHeight
                    Layout.minimumHeight: Math.max(13, parent.parent.height * 0.018) * 1.5
                    clip: true

                    StyledText {
                        id: artistText
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        font.pixelSize: Math.max(13, parent.parent.height * 0.018)
                        color: blendedColors.colSubtext
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: root.player?.trackArtist || "Unknown Artist"

                        Behavior on text {
                            SequentialAnimation {
                                NumberAnimation { target: artistText; property: "x"; to: -artistText.width; duration: 150; easing.type: Easing.InQuad }
                                PropertyAction { target: artistText; property: "text" }
                                NumberAnimation { target: artistText; property: "x"; from: artistText.width; to: 0; duration: 150; easing.type: Easing.OutQuad }
                            }
                        }
                    }
                }
            }

            // ── Lyrics ──
            Item {
                id: lyricsItem
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property bool hasSyncedLines: LyricsService.syncedLines.length > 0
                readonly property bool geniusEnabled: Config.options.lyricsService.enableGenius
                readonly property bool lrclibEnabled: Config.options.lyricsService.enableLrclib

                Component.onCompleted: {
                    if (!geniusEnabled && !lrclibEnabled) return
                    LyricsService.initiliazeLyrics()
                }

                FadeLoader {
                    shown: !lyricsItem.hasSyncedLines
                    anchors.fill: parent
                    sourceComponent: LyricsFlickable {
                        anchors.fill: parent
                        player: root.player
                        fontPixelSize: Math.max(16, parent.height * 0.024)
                        textColor: blendedColors.colOnLayer0
                        loadingIndicatorSize: 96
                        indicatorColor: ColorUtils.applyAlpha(blendedColors.colPrimary, 0.2)
                        shapeColor: blendedColors.colPrimary
                    }
                }
                
                FadeLoader {
                    shown: lyricsItem.hasSyncedLines
                    anchors.fill: parent
                    sourceComponent: LyricsSyllable {
                        anchors.fill: parent
                        largeFontSize: Math.max(20, parent.height * 0.04)
                        activeColor: blendedColors.colPrimary
                    }
                }
            }

            // ── Progress ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: parent.height * 0.01
                spacing: 12

                StyledText {
                    font.pixelSize: (Appearance && Appearance.pixelSize) ? Appearance.pixelSize.normal : 16
                    color: blendedColors.colSubtext
                    font.letterSpacing: -0.4
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player ? root.player.position : 0)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                    Loader {
                        id: sliderLoader
                        anchors.fill: parent
                        active: root.player ? (root.player.canSeek ?? false) : false
                        sourceComponent: StyledSlider {
                            configuration: StyledSlider.Configuration.Wavy
                            highlightColor: blendedColors.colPrimary
                            trackColor: blendedColors.colSecondaryContainer
                            handleColor: blendedColors.colPrimary
                            value: (root.player && StringUtils.normalizeTime(root.player.length) > 0) ? (StringUtils.normalizeTime(root.player.position) / StringUtils.normalizeTime(root.player.length)) : 0
                            onMoved: if (root.player) root.player.position = value * root.player.length
                        }
                    }

                    Loader {
                        id: progressBarLoader
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                        }
                        active: root.player ? !(root.player.canSeek ?? false) : false
                        sourceComponent: StyledProgressBar {
                            wavy: root.player ? root.player.isPlaying : false
                            highlightColor: blendedColors.colPrimary
                            trackColor: blendedColors.colSecondaryContainer
                            value: (root.player && StringUtils.normalizeTime(root.player.length) > 0) ? (StringUtils.normalizeTime(root.player.position) / StringUtils.normalizeTime(root.player.length)) : 0
                        }
                    }
                }

                StyledText {
                    font.pixelSize: (Appearance && Appearance.pixelSize) ? Appearance.pixelSize.normal : 16
                    color: blendedColors.colSubtext
                    font.letterSpacing: -0.4
                    font.features: { "tnum": 1 }
                    text: StringUtils.friendlyTimeForSeconds(root.player ? root.player.length : 0)
                }
            }

            // ── Controls ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: parent.height * 0.02
                Layout.preferredHeight: parent.height * 0.11
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                RippleButton {
                    property real baseSize: Math.max(42, parent.parent.height * 0.06)
                    implicitWidth: baseSize * 1.5
                    implicitHeight: baseSize * 1.5
                    buttonRadius: (Appearance && Appearance.rounding) ? Appearance.rounding.full : baseSize / 2
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => { if (root.player) root.player.previous() }
                    contentItem: MaterialSymbol {
                        iconSize: 25
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "skip_previous"
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(70, parent.parent.height * 0.1)
                    Layout.fillWidth: true
                    implicitHeight: baseSize
                    buttonRadius: (root.player && root.player.isPlaying) ? ((Appearance && Appearance.rounding) ? Appearance.rounding.verylarge : 15) : baseSize / 2
                    colBackground: (root.player && root.player.isPlaying) ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
                    colBackgroundHover: (root.player && root.player.isPlaying) ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
                    colRipple: (root.player && root.player.isPlaying) ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive
                    downAction: () => { if (root.player) root.player.togglePlaying() }
                    contentItem: MaterialSymbol {
                        iconSize: 50
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: (root.player && root.player.isPlaying) ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                        text: (root.player && root.player.isPlaying) ? "pause" : "play_arrow"
                        Behavior on color {
                            animation: (Appearance && Appearance.animation && Appearance.animation.elementMoveFast) ? Appearance.animation.elementMoveFast.colorAnimation.createObject(this) : null
                        }
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(42, parent.parent.height * 0.06)
                    implicitWidth: baseSize * 1.5
                    implicitHeight: baseSize * 1.5
                    buttonRadius: (Appearance && Appearance.rounding) ? Appearance.rounding.full : baseSize / 2
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => { if (root.player) root.player.next() }
                    contentItem: MaterialSymbol {
                        iconSize: 25
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "skip_next"
                    }
                }
            }

            // ── Volume ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8

                RippleButton {
                    property real baseSize: Math.max(36, parent.parent.height * 0.05)
                    implicitWidth: baseSize
                    implicitHeight: baseSize
                    buttonRadius: (Appearance && Appearance.rounding) ? Appearance.rounding.large : 0
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => { if (root.player) root.player.volume = root.player.volume > 0 ? 0 : 1.0 }
                    contentItem: MaterialSymbol {
                        iconSize: 18
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: (root.player ? (root.player.volume ?? 1) : 1) <= 0 ? "volume_off"
                            : (root.player ? (root.player.volume ?? 1) : 1) < 0.5 ? "volume_down"
                            : "volume_up"
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(36, parent.parent.height * 0.05)
                    Layout.fillWidth: true
                    implicitHeight: baseSize
                    buttonRadius: (Appearance && Appearance.rounding) ? Appearance.rounding.large : 0
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => { if (root.player) root.player.volume = Math.max(0, (root.player.volume ?? 1) - 0.1) }
                    contentItem: MaterialSymbol {
                        iconSize: 18
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "volume_down"
                    }
                }

                RippleButton {
                    property real baseSize: Math.max(36, parent.parent.height * 0.05)
                    Layout.fillWidth: true
                    implicitHeight: baseSize
                    buttonRadius: (Appearance && Appearance.rounding) ? Appearance.rounding.large : 0
                    colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 0.7)
                    colBackgroundHover: blendedColors.colSecondaryContainerHover
                    colRipple: blendedColors.colSecondaryContainerActive
                    downAction: () => { if (root.player) root.player.volume = Math.min(1.5, (root.player.volume ?? 1) + 0.1) }
                    contentItem: MaterialSymbol {
                        iconSize: 18
                        fill: 1
                        horizontalAlignment: Text.AlignHCenter
                        color: blendedColors.colOnSecondaryContainer
                        text: "volume_up"
                    }
                }
            }
        }
    }
}