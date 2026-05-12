pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Transport controls for the media card. Geometry mirrors the original
// PlayerControl inline layout exactly:
//   trackTime ------ (empty)                   (playPauseButton overlays,
//   [ prev ][  <default slot: MediaProgress>  ][ next ]   anchored top-right)
Item {
    id: root

    property MprisPlayer player: null
    property var colors: null
    property real playPauseSize: 44
    property real position: 0
    property real length: 0

    signal lyricsRequested()

    default property alias content: slot.data

    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight + 5

    function formatTime(sec) {
        const s = Math.max(0, Math.floor(sec ?? 0));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    component TrackChangeButton: RippleButton {
        implicitWidth: 32
        implicitHeight: 32
        property string iconName
        property bool isFilled: true
        colBackground: ColorUtils.transparentize(root.colors?.colSecondaryContainer ?? Appearance.m3colors.m3secondaryContainer, 1)
        colBackgroundHover: root.colors?.colSecondaryContainerHover ?? Appearance.colors.colSecondaryContainerHover
        colRipple: root.colors?.colSecondaryContainerActive ?? Appearance.colors.colSecondaryContainerActive
        buttonRadius: 999

        contentItem: MaterialSymbol {
            text: iconName
            fill: isFilled ? 1 : 0
            iconSize: 18
            color: root.colors?.colOnSecondaryContainer ?? Appearance.m3colors.m3onSecondaryContainer
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic } }
        }
    }

    StyledText {
        id: trackTime
        anchors.top: parent.top
        anchors.left: parent.left
        font.pixelSize: 11
        color: root.colors?.colSubtext ?? Appearance.m3colors.m3onSurfaceVariant
        elide: Text.ElideRight
        text: `${StringUtils.friendlyTimeForSeconds(root.position)} / ${StringUtils.friendlyTimeForSeconds(root.length)}`
    }

    RowLayout {
        id: sliderRow
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        spacing: 4

        TrackChangeButton {
            iconName: "push_pin"
            isFilled: MprisController.pinnedPlayer == root.player
            onClicked: {
                GlobalStates.superReleaseMightTrigger = false;
                if (MprisController.pinnedPlayer == root.player) {
                    MprisController.setActivePlayer(null);
                } else {
                    MprisController.setActivePlayer(root.player);
                }
            }
        }

        TrackChangeButton {
            iconName: "skip_previous"
            onClicked: {
                GlobalStates.superReleaseMightTrigger = false;
                root.player?.previous();
            }
        }

        RippleButton {
            id: playPauseButton
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            onClicked: {
                GlobalStates.superReleaseMightTrigger = false;
                root.player?.togglePlaying();
            }

            buttonRadius: root.player?.playbackState === MprisPlaybackState.Playing ? 10 : 20
            colBackground: root.player?.playbackState === MprisPlaybackState.Playing
                ? (root.colors?.colPrimary ?? Appearance.m3colors.m3primary)
                : (root.colors?.colSecondaryContainer ?? Appearance.m3colors.m3secondaryContainer)
            colBackgroundHover: root.player?.playbackState === MprisPlaybackState.Playing
                ? (root.colors?.colPrimaryHover ?? Appearance.colors.colPrimaryHover)
                : (root.colors?.colSecondaryContainerHover ?? Appearance.colors.colSecondaryContainerHover)
            colRipple: root.player?.playbackState === MprisPlaybackState.Playing
                ? (root.colors?.colPrimaryActive ?? Appearance.colors.colPrimaryActive)
                : (root.colors?.colSecondaryContainerActive ?? Appearance.colors.colSecondaryContainerActive)

            contentItem: MaterialSymbol {
                text: root.player?.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                fill: 1
                iconSize: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.player?.playbackState === MprisPlaybackState.Playing
                    ? (root.colors?.colOnPrimary ?? Appearance.m3colors.m3onPrimary)
                    : (root.colors?.colOnSecondaryContainer ?? Appearance.m3colors.m3onSecondaryContainer)
                Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic } }
            }
        }

        Item {
            id: slot
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        TrackChangeButton {
            iconName: "skip_next"
            onClicked: {
                GlobalStates.superReleaseMightTrigger = false;
                root.player?.next();
            }
        }

        TrackChangeButton {
            iconName: "lyrics"
            onClicked: {
                GlobalStates.superReleaseMightTrigger = false;
                root.lyricsRequested();
            }
        }
    }
}
