import qs.modules.common.widgets
import qs.modules.common
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    property string buttonIcon
    property alias iconSize: iconWidget.iconSize
    property alias placeholderText: textField.placeholderText
    property alias inputText: textField.text
    signal accepted(string value)

    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 8 * 2
    font.pixelSize: Appearance.font.pixelSize.small
    
    // Clicking the button focuses the text field
    onClicked: textField.forceActiveFocus()

    property color normalColor: ColorUtils.transparentize(Appearance?.colors.colLayer1Hover, 1) 
    property color highlightColor: Appearance.colors.colSecondaryContainer

    colBackground: normalColor

    SearchHandler {
        searchString: root.inputText
    }

    HighlightOverlay {
        id: highlightOverlay
        anchors.fill: parent
        radius: root.buttonEffectiveRadius
        color: root.highlightColor
    }

    contentItem: RowLayout {
        spacing: 10
        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            opacity: root.enabled ? 1 : 0.4
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: false
            text: root.inputText
            visible: text !== "" && !textField.activeFocus
            font.pixelSize: root.font.pixelSize
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }
        MaterialTextField {
            id: textField
            Layout.fillWidth: true
            font.pixelSize: root.font.pixelSize
            color: Appearance.colors.colOnSecondaryContainer
            onAccepted: root.accepted(text)
            // Use background of MaterialTextField to make it look integrated
            background: Item {}
        }
    }
}
