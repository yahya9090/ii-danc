pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services

Item {
    id: root

    property var notif: null

    property string timeString: NotificationUtils.getFriendlyNotifTimeString(notif?.time)

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.timeString = NotificationUtils.getFriendlyNotifTimeString(root.notif?.time)
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        NotificationAppIcon {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 2
            implicitSize: 38
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            image:    root.notif?.image ?? ""
            appIcon:  root.notif?.appIcon ?? ""
            summary:  root.notif?.summary ?? ""
            urgency:  root.notif?.urgency ?? "normal"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.notif?.appName ?? ""
                    elide: Text.ElideRight
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                StyledText {
                    visible: root.timeString.length > 0
                    text: root.timeString
                    horizontalAlignment: Text.AlignRight
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.notif?.summary ?? ""
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Appearance.m3colors.m3onSurface
                font.weight: Font.DemiBold
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            StyledText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: text.length > 0
                text: root.notif?.body ?? ""
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
                color: Appearance.m3colors.m3onSurface
                opacity: 0.8
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }
    }
}
