pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Services.Mpris
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// Seek surface for the media card. Shows the wavy StyledSlider when the player
// reports canSeek, otherwise a wavy StyledProgressBar. Emits seekRequested with
// the target position in seconds so the orchestrator can update both the
// native MPRIS player and the browser poller's cached position.
Item {
    id: root

    property MprisPlayer player: null
    property real position: 0
    property real length: 0
    property bool animating: false
    property bool browserPlayer: false
    property var colors: null

    signal seekRequested(real positionSec)

    implicitHeight: Math.max(32, sliderLoader.implicitHeight, progressBarLoader.implicitHeight)
    clip: false

    readonly property real normLength: StringUtils.normalizeTime(root.length)
    readonly property real normPosition: StringUtils.normalizeTime(root.position)

    Loader {
        id: sliderLoader
        anchors.fill: parent
        active: root.player?.canSeek ?? false
        sourceComponent: StyledSlider {
            configuration: StyledSlider.Configuration.Wavy
            thickFill: true
            stopIndicatorValues: []
            highlightColor: root.colors?.colPrimary ?? Appearance.m3colors.m3primary
            trackColor: root.colors?.colSecondaryContainer ?? Appearance.m3colors.m3secondaryContainer
            handleColor: root.colors?.colPrimary ?? Appearance.m3colors.m3primary
            value: root.normLength > 0 ? (root.normPosition / root.normLength) : 0
            onMoved: {
                GlobalStates.superReleaseMightTrigger = false;
                root.seekRequested(value * root.normLength);
            }
        }
    }

    Loader {
        id: progressBarLoader
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
        }
        active: !(root.player?.canSeek ?? false)
        sourceComponent: StyledProgressBar {
            wavy: root.animating
            highlightColor: root.colors?.colPrimary ?? Appearance.m3colors.m3primary
            trackColor: root.colors?.colSecondaryContainer ?? Appearance.m3colors.m3secondaryContainer
            value: root.normLength > 0 ? (root.normPosition / root.normLength) : 0
        }
    }
}
