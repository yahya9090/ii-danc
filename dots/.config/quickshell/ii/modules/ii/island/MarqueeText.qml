import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Continuous horizontal scroll for text that overflows. Falls back to a
// single static StyledText when the text fits.
Item {
    id: root

    property string text: ""
    property int fontSize: Appearance.font.pixelSize.normal
    property int fontWeight: Font.Normal
    property string fontFamily: Appearance.font.family.main
    property color textColor: Appearance.m3colors.m3onSurface
    property int gap: 32
    property int pauseAtStart: 800
    property real pixelsPerSecond: 40
    property bool running: true

    implicitHeight: probe.implicitHeight
    clip: true

    StyledText {
        id: probe
        visible: false
        text: root.text
        font {
            family: root.fontFamily
            pixelSize: root.fontSize
            weight: root.fontWeight
        }
        color: root.textColor
    }

    readonly property bool overflowing: probe.implicitWidth > width

    StyledText {
        id: staticLabel
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        text: root.text
        font {
            family: root.fontFamily
            pixelSize: root.fontSize
            weight: root.fontWeight
        }
        color: root.textColor
        elide: Text.ElideRight
        visible: !root.overflowing
    }

    Item {
        id: scroller
        anchors.verticalCenter: parent.verticalCenter
        height: probe.implicitHeight
        width: parent.width
        visible: root.overflowing

        Row {
            id: scrollRow
            spacing: root.gap
            x: 0

            StyledText {
                id: copyA
                text: root.text
                font {
                    family: root.fontFamily
                    pixelSize: root.fontSize
                    weight: root.fontWeight
                }
                color: root.textColor
            }
            StyledText {
                text: root.text
                font {
                    family: root.fontFamily
                    pixelSize: root.fontSize
                    weight: root.fontWeight
                }
                color: root.textColor
            }

            SequentialAnimation on x {
                running: root.running && root.overflowing
                loops: Animation.Infinite
                PauseAnimation { duration: root.pauseAtStart }
                NumberAnimation {
                    from: 0
                    to: -(copyA.implicitWidth + root.gap)
                    duration: Math.max(4000, ((copyA.implicitWidth + root.gap) / root.pixelsPerSecond) * 1000)
                    easing.type: Easing.Linear
                }
            }
        }
    }
}
