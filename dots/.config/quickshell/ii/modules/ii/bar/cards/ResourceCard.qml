import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

SectionCard {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredWidth: 180
    showDivider: false

    property string resourceName: ""
    property string resourceValueText: ""
    property real resourcePercentage: 0
    property color highlightColor: Appearance.colors.colPrimary
    property int resourceNameFontSize: Appearance.font.pixelSize.small
    property int resourceValueFontSize: Appearance.font.pixelSize.normal

    // Expose extra content below the progress bar
    default property alias extraContent: extraColumn.data

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: root.spacing

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: root.resourceName
                font.pixelSize: root.resourceNameFontSize
                color: Appearance.colors.colOnSurfaceVariant
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            StyledText {
                text: root.resourceValueText
                font.pixelSize: root.resourceValueFontSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        StyledProgressBar {
            visible: root.resourcePercentage >= 0
            Layout.fillWidth: true
            value: root.resourcePercentage
            highlightColor: root.highlightColor
            Layout.alignment: Qt.AlignBottom
        }

        ColumnLayout {
            id: extraColumn
            visible: root.extraContent.length > 0
            Layout.fillWidth: true
            Layout.topMargin: parent.spacing * 2
            spacing: 12
        }
    }
}
