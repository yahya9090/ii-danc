pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property bool expanded: false

    readonly property real level: Battery.percentage
    readonly property bool charging: Battery.isCharging
    readonly property bool low: Battery.isLow
    readonly property bool critical: Battery.isCritical
    
    readonly property string style: Config.options.battery.style

    readonly property color tint: critical
        ? Appearance.m3colors.m3error
        : (low ? "#e0c060"
              : (charging ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface))

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 8
        opacity: root.expanded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic } }

        IslandBatteryIcon {
            size: 16
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            color: Appearance.m3colors.m3onSurface
            font.weight: Font.Medium
            text: Math.round(root.level * 100) + "%" + (root.charging ? " · Charging" : "")
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic } }

        MaterialShape {
            Layout.preferredWidth: 56
            Layout.preferredHeight: 56
            Layout.alignment: Qt.AlignVCenter
            color: Appearance.colors.colSecondaryContainer
            shape: MaterialShape.Shape.Cookie7Sided
            
            IslandBatteryIcon {
                anchors.centerIn: parent
                vertical: true
                size: root.style === "oneui" ? 40 : 22
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            StyledText {
                text: root.charging ? Translation.tr("Charging") : (root.low ? Translation.tr("Low battery") : Translation.tr("On battery"))
                color: Appearance.m3colors.m3onSurface
                font.weight: Font.DemiBold
                font.pixelSize: Appearance.font.pixelSize.normal
            }
            StyledText {
                text: Math.round(root.level * 100) + "%"
                color: Appearance.m3colors.m3onSurface
                font.pixelSize: Appearance.font.pixelSize.small
            }
            StyledText {
                text: Battery.isCharging ? Translation.tr("AC Power") : Translation.tr("Discharging")
                color: Appearance.m3colors.m3onSurface
                opacity: 0.7
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            Item { Layout.fillHeight: true }
        }
    }
}

