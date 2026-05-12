pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string mode: "volume" // volume, brightness, gamma, media
    property string icon: "volume_up"
    property string label:    ""
    property real   value: 0
    property real   from: 0
    property real   to: 1.0
    property var    shape: MaterialShape.Shape.Circle
    property string protectionMessage: ""

    readonly property real barHeight: 4
    readonly property real clamped: Math.max(0, Math.min(1, (value - from) / (to - from)))

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 20
        spacing: 12

        Item {
            implicitWidth: 32
            implicitHeight: 32
            Layout.alignment: Qt.AlignVCenter

            MaterialShapeWrappedMaterialSymbol {
                anchors.centerIn: parent
                iconSize: 22
                shape: root.protectionMessage !== "" ? MaterialShape.Shape.Square : root.shape
                text: root.protectionMessage !== "" ? "dangerous" : root.icon
                color: root.protectionMessage !== "" ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                colSymbol: root.protectionMessage !== "" ? Appearance.m3colors.m3onError : Appearance.colors.colOnPrimary
                
                readonly property real rotationRatio: (root.to - root.from) !== 0 ? (root.value - root.from) / (root.to - root.from) : 0
                rotation: (root.mode === "brightness" || root.mode === "gamma" || root.mode === "volume") ? rotationRatio * 360 : 0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: root.barHeight / 2
                Layout.rightMargin: root.barHeight / 2

                StyledText {
                    Layout.fillWidth: true
                    text: root.protectionMessage !== "" ? root.protectionMessage : root.label
                    color: root.protectionMessage !== "" ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: root.protectionMessage !== "" ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                StyledText {
                    visible: root.protectionMessage === ""
                    text: {
                        if (root.mode === "volume" || root.mode === "media" || root.mode === "gamma") {
                            return Math.round(root.value * 100);
                        }
                        return Math.round(root.clamped * 100);
                    }
                    horizontalAlignment: Text.AlignRight
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: root.barHeight

                Rectangle {
                    id: fill
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: root.barHeight
                    radius: height / 2
                    color: root.protectionMessage !== "" ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                    width: parent.width * root.clamped
                    Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: root.barHeight
                    width: Math.max(0, parent.width - fill.width - root.barHeight)
                    radius: height / 2
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.barHeight
                    height: root.barHeight
                    radius: height / 2
                    color: root.protectionMessage !== "" ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                    Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                }
            }
        }
    }
}
