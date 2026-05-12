
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Rectangle {
    id: rect
    property real sizeMultiplier: 1.0
    readonly property string dialStyle: Config.options.background.widgets.clock.cookie.dialNumberStyle

    StyledText {
        anchors.centerIn: parent
        color: Appearance.colors.colSecondaryHover
        text: Qt.locale().toString(DateTime.clock.date, "dd")
        font {
            family: Appearance.font.family.expressive
            pixelSize: 20 * rect.sizeMultiplier
            weight: 1000
        }
    }
}
