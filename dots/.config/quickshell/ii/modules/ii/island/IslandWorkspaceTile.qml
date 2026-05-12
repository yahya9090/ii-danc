pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Rectangle {
    id: root
    
    required property int workspaceId
    property var overviewRoot
    property bool isActive: false
    property bool hoveredWhileDragging: false
    
    property color defaultWorkspaceColor: Appearance.colors.colSurfaceContainerLow
    property color hoveredWorkspaceColor: ColorUtils.mix(defaultWorkspaceColor, Appearance.colors.colLayer1Hover, 0.1)
    property color hoveredBorderColor: Appearance.colors.colLayer2Hover
    
    color: (mouseArea.containsMouse || hoveredWhileDragging) ? hoveredWorkspaceColor : defaultWorkspaceColor
    
    // Borders only show when dragging, matching OverviewWidget.qml
    border.width: 2
    border.color: hoveredWhileDragging ? hoveredBorderColor : "transparent"
    
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    StyledText {
        anchors.centerIn: parent
        text: root.workspaceId
        font {
            pixelSize: root.height * 0.4
            weight: Font.DemiBold
            family: Appearance.font.family.expressive
        }
        color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.8)
        
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onClicked: {
            Hyprland.dispatch(`workspace ${root.workspaceId}`)
            GlobalStates.workspacesOverviewOpen = false
        }
    }
    
    DropArea {
        anchors.fill: parent
        onEntered: {
            root.hoveredWhileDragging = true
            root.overviewRoot.draggingTargetWorkspace = root.workspaceId
        }
        onExited: {
            root.hoveredWhileDragging = false
            if (root.overviewRoot.draggingTargetWorkspace === root.workspaceId) {
                root.overviewRoot.draggingTargetWorkspace = -1
            }
        }
    }
}
