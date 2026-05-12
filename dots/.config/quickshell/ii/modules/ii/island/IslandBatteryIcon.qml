pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root
    property real size: 20
    property bool vertical: false
    
    readonly property real level: Battery.percentage
    readonly property bool charging: Battery.isCharging
    readonly property bool pluggedIn: Battery.isPluggedIn
    readonly property bool effectivelyCharging: charging || pluggedIn
    readonly property bool low: Battery.isLow
    readonly property bool critical: Battery.isCritical
    
    readonly property bool isPowerSaving: typeof PowerProfiles !== 'undefined' && PowerProfiles.profile === PowerProfile.PowerSaver
    readonly property bool isPerformance: typeof PowerProfiles !== 'undefined' && PowerProfiles.profile === PowerProfile.Performance

    readonly property string style: Config.options.battery.style

    implicitWidth: {
        if (vertical) {
            if (root.style === "oneui") return size * (21/40);
            return size; // Android16 and Default are horizontal-only usually, so we treat size as height and width follows
        }
        if (root.style === "android16") return (26 + 1 + 2) * (size / 14);
        if (root.style === "oneui") return 30 * (size / 18);
        return size * (28/13);
    }
    implicitHeight: vertical && root.style === "oneui" ? size * (40/21) : size

    readonly property color fillColor: {
        if (root.critical && !root.effectivelyCharging) return "#E53935";
        if (root.low && !root.effectivelyCharging) return "#FB8C00";
        if (root.effectivelyCharging) return "#43A047";
        if (root.isPowerSaving) return "#FFC917";
        if (root.isPerformance) return "#42A5F5";
        return Appearance.colors.colOnSecondaryContainer;
    }

    readonly property color frameColor: {
        if (root.critical && !root.effectivelyCharging) return Appearance.m3colors.m3error;
        if (root.low && !root.effectivelyCharging) return Appearance.m3colors.m3error;
        return Appearance.colors.colOnSecondaryContainer;
    }

    // Android 16 Style
    Item {
        id: android16Battery
        visible: root.style === "android16"
        anchors.centerIn: parent
        height: root.size
        width: height * (29 / 14)

        Row {
            anchors.centerIn: parent
            spacing: Math.max(1, Math.round(root.size / 14))

            ClippedProgressBar {
                id: batteryProgress
                width: root.size * (26 / 14)
                height: root.size
                radius: 4.5 * (root.size / 14)
                value: root.level
                highlightColor: root.fillColor
                trackColor: Qt.rgba(Appearance.colors.colOnSurface.r, Appearance.colors.colOnSurface.g, Appearance.colors.colOnSurface.b, 0.3)

                textMask: Item {
                    width: batteryProgress.width
                    height: batteryProgress.height
                    StyledText {
                        anchors.centerIn: parent
                        font.pixelSize: Math.round(10 * (root.size / 14))
                        font.weight: Font.Bold
                        text: batteryProgress.text
                        color: (root.low && !root.effectivelyCharging) ? Appearance.m3colors.m3onError : Appearance.colors.colOnSurface
                    }
                }
            }

            Rectangle {
                width: Math.max(1, 2 * (root.size / 14))
                height: Math.max(2, 6 * (root.size / 14))
                anchors.verticalCenter: parent.verticalCenter
                radius: 1
                color: (root.level >= 0.98) ? batteryProgress.highlightColor : batteryProgress.trackColor
            }
        }

        MaterialSymbol {
            visible: root.effectivelyCharging
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.right
            anchors.horizontalCenterOffset: -1
            text: "bolt"
            iconSize: 17 * (root.size / 14)
            fill: 1
            color: Appearance.colors.colLayer0
            z: 2
        }
        MaterialSymbol {
            visible: root.effectivelyCharging
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.right
            anchors.horizontalCenterOffset: -1
            text: "bolt"
            iconSize: 16 * (root.size / 14)
            fill: 1
            color: Appearance.colors.colOnSecondaryContainer
            z: 3
        }
    }

    // OneUI Style
    ClippedProgressBar {
        id: oneuiBattery
        visible: root.style === "oneui"
        anchors.centerIn: parent
        value: root.level
        highlightColor: root.fillColor
        vertical: root.vertical
        width: root.vertical ? root.size * (21/40) : 30 * (root.size / 18)
        height: root.vertical ? root.size : root.size

        textMask: Item {
            width: oneuiBattery.width
            height: oneuiBattery.height

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0
                visible: root.vertical

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    fill: 1
                    text: root.effectivelyCharging ? "bolt" : "battery_android_full"
                    iconSize: Math.round(root.size * 0.2)
                    animateChange: true
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: Math.round(root.size * 0.25)
                    font.weight: Font.DemiBold
                    text: oneuiBattery.text
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 0
                visible: !root.vertical
                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    fill: 1
                    text: "bolt"
                    iconSize: Math.round(8 * (root.size / 18))
                    visible: root.effectivelyCharging && root.level < 1
                }
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Math.round(10 * (root.size / 18))
                    font.weight: Font.DemiBold
                    text: oneuiBattery.text
                }
            }
        }
    }

    // Default Style
    Item {
        id: batteryContainer
        visible: root.style !== "android16" && root.style !== "oneui"
        anchors.centerIn: parent
        height: root.size
        width: height * (28 / 13)

        Item {
            id: fillClipping
            clip: true
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: parent.width * root.level

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: parent.height * (3/14)
                height: parent.height - (parent.height * (6/14))
                width: (parent.width * (24/28)) - (parent.height * (6/14))
                radius: 1.5
                color: root.fillColor
            }
        }

        CustomIcon {
            anchors.fill: parent
            source: "Battery.svg"
            colorize: true
            color: root.frameColor
            z: 1
        }

        MaterialSymbol {
            visible: root.effectivelyCharging
            anchors.top: parent.top
            anchors.topMargin: -parent.height * (5/14)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -(parent.width * (4 / 28)) / 2
            text: "bolt"
            iconSize: parent.height * (17/14)
            fill: 1
            color: Appearance.colors.colLayer0
            z: 2
        }
        MaterialSymbol {
            visible: root.effectivelyCharging
            anchors.top: parent.top
            anchors.topMargin: -parent.height * (6/14)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -(parent.width * (4 / 28)) / 2
            text: "bolt"
            iconSize: parent.height * (16/14)
            fill: 1
            color: Appearance.colors.colOnSecondaryContainer
            z: 3
        }
    }
}
