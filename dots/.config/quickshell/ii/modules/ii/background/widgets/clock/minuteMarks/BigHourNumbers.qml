pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    property real sizeMultiplier: 1.0
    property real numberSize: 80 * sizeMultiplier
    property real margins: 10 * sizeMultiplier
    property color color: Appearance.colors.colOnSecondaryContainer

    property int hours: 12
    property int numbers: 4
    property real fontSize: 80 * sizeMultiplier

    Repeater {
        model: root.numbers

        Item {
            id: numberItem
            required property int index
            rotation: 360 / root.numbers * (index + 1)
            anchors.fill: parent
            
            Item {
                implicitWidth: root.numberSize
                implicitHeight: implicitWidth
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: root.margins
                }
                StyledText {
                    color: root.color
                    anchors.centerIn: parent
                    text: root.hours / root.numbers * (numberItem.index + 1)
                    rotation: -numberItem.rotation

                    font {
                        family: Appearance.font.family.reading
                        pixelSize: root.fontSize
                        weight: Font.Black
                    }
                }
            }
        }
    }
}
