import qs.modules.common
import qs.services
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    Component.onCompleted: NetworkSpeed.start()
    Component.onDestruction: NetworkSpeed.stop()

    TextMetrics {
        id: speedMetrics
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.family: Appearance.font.family.numbers
        text: "999.9 MB/s"
    }

    RowLayout {
        id: rowLayout
        spacing: 8
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        RowLayout {
            spacing: 2
            MaterialSymbol {
                iconSize: 16
                text: "arrow_downward"
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: NetworkSpeed.downloadSpeedString
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colOnLayer1
                Layout.preferredWidth: speedMetrics.width
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            spacing: 2
            MaterialSymbol {
                iconSize: 16
                text: "arrow_upward"
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: NetworkSpeed.uploadSpeedString
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colOnLayer1
                Layout.preferredWidth: speedMetrics.width
                horizontalAlignment: Text.AlignRight
            }
        }
    }
    
    StyledPopup {
        hoverTarget: root
        Column {
            id: popupContent
            spacing: 8
            width: 200 // Ensure a consistent width for the popup

            StyledPopupHeaderRow {
                icon: "swap_vert"
                label: Translation.tr("Network Traffic")
            }
            
            Column {
                spacing: 4
                width: parent.width
                
                StyledPopupValueRow {
                    width: parent.width
                    icon: "arrow_downward"
                    label: Translation.tr("Download")
                    value: NetworkSpeed.downloadSpeedString
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "arrow_upward"
                    label: Translation.tr("Upload")
                    value: NetworkSpeed.uploadSpeedString
                }
                StyledPopupValueRow {
                    width: parent.width
                    icon: "settings_ethernet"
                    label: Translation.tr("Interface")
                    value: NetworkSpeed.activeInterface
                }
            }
        }
    }
}
