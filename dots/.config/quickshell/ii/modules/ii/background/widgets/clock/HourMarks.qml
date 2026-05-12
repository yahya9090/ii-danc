pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick

Item {
    id: root
    property real sizeMultiplier: 1.0
    property real implicitSize: 135 * sizeMultiplier
    property real markLength: 12 * sizeMultiplier
    property real markWidth: 4 * sizeMultiplier
    property color color: Appearance.colors.colOnSecondaryContainer
    property color colOnBackground: Appearance.colors.colSecondaryContainer
    property real padding: 8 * sizeMultiplier

    Rectangle {
        color: root.color
        anchors.centerIn: parent
        implicitWidth: root.implicitSize
        implicitHeight: root.implicitSize
        radius: width / 2

        // Hour mark lines
        Repeater {
            model: 12

            Item {
                required property int index
                anchors.fill: parent
                rotation: 360 / 12 * index 

                Rectangle {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: root.padding
                    }
                    implicitWidth: root.markLength
                    implicitHeight: root.markWidth

                    radius: width / 2
                    color: root.colOnBackground
                }
            }
        }
    }

}
