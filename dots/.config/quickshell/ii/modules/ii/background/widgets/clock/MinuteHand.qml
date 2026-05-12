pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick

Item {
    id: root
    anchors.fill: parent

    required property int clockMinute
    property real sizeMultiplier: 1.0
    property string style: "medium"
    property real handLength: 95 * sizeMultiplier
    property real handWidth: (style === "bold" ? 20 : style === "medium" ? 12 : 5) * sizeMultiplier
    property color color: Appearance.colors.colTertiary

    rotation: -90 + (360 / 60) * root.clockMinute
    Behavior on rotation {
        animation: RotationAnimation {
            direction: RotationAnimation.Clockwise
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: {
            let position = parent.width / 2 - root.handWidth / 2;
            if (root.style === "classic") position -= 15 * root.sizeMultiplier;
            return position;
        }
        width: root.handLength
        height: root.handWidth
        
        radius: root.style === "classic" ? 2 * root.sizeMultiplier : root.handWidth / 2
        color: root.color

        Behavior on height {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        Behavior on x {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }
}
