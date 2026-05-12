pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property var notif: null

    readonly property bool isCritical: notif?.urgency === "critical"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 14
        spacing: 10

        NotificationAppIcon {
            Layout.alignment: Qt.AlignVCenter
            implicitSize: 28
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            image:    root.notif?.image ?? ""
            appIcon:  root.notif?.appIcon ?? ""
            summary:  root.notif?.summary ?? ""
            urgency:  root.notif?.urgency ?? "normal"
        }

        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
            color: root.isCritical ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurface
            font.weight: Font.DemiBold
            text: root.notif?.summary ?? ""
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }
}
