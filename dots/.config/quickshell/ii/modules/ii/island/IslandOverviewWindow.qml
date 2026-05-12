pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    
    required property var toplevel
    required property var windowData
    property var monitorData
    property var overviewRoot
    property real scale: 1.0
    property real xOffset: 0
    property real yOffset: 0
    
    // Grid position info for rounding
    property real workspaceImplicitWidth
    property real workspaceImplicitHeight
    property int workspaceColIndex
    property int workspaceRowIndex
    property int workspaceColumns
    property int workspaceRows
    
    // Position calculation logic from main overview
    property real xWithinWorkspaceWidget: Math.max(0, (windowData.at[0] - (root.monitorData?.x ?? 0) - (root.monitorData?.reserved?.[0] ?? 0)) * root.scale)
    property real yWithinWorkspaceWidget: Math.max(0, (windowData.at[1] - (root.monitorData?.y ?? 0) - (root.monitorData?.reserved?.[1] ?? 0)) * root.scale)
    
    property real targetX: xWithinWorkspaceWidget + xOffset
    property real targetY: yWithinWorkspaceWidget + yOffset
    
    x: Drag.active ? x : targetX
    y: Drag.active ? y : targetY
    width: Math.max(8, windowData.size[0] * root.scale)
    height: Math.max(8, windowData.size[1] * root.scale)
    
    // Important for drag and drop reliability:
    // 1. Manually manage Drag.active
    // 2. Set Drag.source to self
    Drag.active: mouseArea.drag.active
    Drag.source: root
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2
    
    z: Drag.active ? 1000 : (windowData.focusHistoryID === 0 ? 10 : 1)
    
    // Radius logic from main overview
    readonly property real largeWorkspaceRadius: Appearance.rounding.large
    readonly property real smallWorkspaceRadius: Appearance.rounding.verysmall
    readonly property real minRadius: Appearance.rounding.small
    
    readonly property bool workspaceAtLeft: workspaceColIndex === 0
    readonly property bool workspaceAtRight: workspaceColIndex === workspaceColumns - 1
    readonly property bool workspaceAtTop: workspaceRowIndex === 0
    readonly property bool workspaceAtBottom: workspaceRowIndex === workspaceRows - 1
    
    readonly property bool workspaceAtTopLeft: (workspaceAtLeft && workspaceAtTop) 
    readonly property bool workspaceAtTopRight: (workspaceAtRight && workspaceAtTop) 
    readonly property bool workspaceAtBottomLeft: (workspaceAtLeft && workspaceAtBottom) 
    readonly property bool workspaceAtBottomRight: (workspaceAtRight && workspaceAtBottom) 
    
    readonly property real distanceFromLeftEdge: xWithinWorkspaceWidget
    readonly property real distanceFromRightEdge: root.workspaceImplicitWidth - (xWithinWorkspaceWidget + root.width)
    readonly property real distanceFromTopEdge: yWithinWorkspaceWidget
    readonly property real distanceFromBottomEdge: root.workspaceImplicitHeight - (yWithinWorkspaceWidget + root.height)
    
    readonly property real distanceFromTopLeftCorner: Math.max(distanceFromLeftEdge, distanceFromTopEdge)
    readonly property real distanceFromTopRightCorner: Math.max(distanceFromRightEdge, distanceFromTopEdge)
    readonly property real distanceFromBottomLeftCorner: Math.max(distanceFromLeftEdge, distanceFromBottomEdge)
    readonly property real distanceFromBottomRightCorner: Math.max(distanceFromRightEdge, distanceFromBottomEdge)
    
    readonly property real topLeftRadius: Math.max((workspaceAtTopLeft ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromTopLeftCorner, minRadius)
    readonly property real topRightRadius: Math.max((workspaceAtTopRight ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromTopRightCorner, minRadius)
    readonly property real bottomLeftRadius: Math.max((workspaceAtBottomLeft ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromBottomLeftCorner, minRadius)
    readonly property real bottomRightRadius: Math.max((workspaceAtBottomRight ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromBottomRightCorner, minRadius)

    property bool initialized: false
    Component.onCompleted: Qt.callLater(() => root.initialized = true)

    Behavior on x {
        enabled: root.initialized && !Drag.active
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(root)
    }
    Behavior on y {
        enabled: root.initialized && !Drag.active
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(root)
    }
    
    // Rounded mask matching main overview
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
        }
    }

    // Window preview fallback background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.1, 0.1, 0.1, 1.0)
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }
    
    ScreencopyView {
        id: windowPreview
        anchors.fill: parent
        captureSource: root.toplevel
        live: true
        z: 1

        // Color overlay for interactions (Matching main overview)
        Rectangle {
            anchors.fill: parent
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            
            color: mouseArea.pressed ? ColorUtils.transparentize(Appearance.colors.colLayer2Active, 0.5) : 
                   mouseArea.containsMouse ? ColorUtils.transparentize(Appearance.colors.colLayer2Hover, 0.7) : 
                   ColorUtils.transparentize(Appearance.colors.colLayer2, 0.9)
            
            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }

        Image {
            id: icon
            anchors.centerIn: parent
            
            // Icon scaling logic from main overview
            property real baseSize: Math.min(root.width, root.height)
            property bool compactMode: Appearance.font.pixelSize.smaller * 4 > root.height || Appearance.font.pixelSize.smaller * 4 > root.width
            property real iconToWindowRatio: 0.45 // Increased from 0.15
            property real iconToWindowRatioCompact: 0.8 // Increased from 0.6
            
            width: baseSize * (compactMode ? iconToWindowRatioCompact : iconToWindowRatio)
            height: width
            sourceSize: Qt.size(width, height)
            source: Quickshell.iconPath(AppSearch.guessIcon(windowData.class), "image-missing")
            opacity: 1.0
            z: 2
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: parent
        
        onReleased: {
            const targetWs = root.overviewRoot.draggingTargetWorkspace
            if (targetWs !== -1 && targetWs !== root.windowData.workspace.id) {
                Hyprland.dispatch(`movetoworkspacesilent ${targetWs}, address:${root.windowData.address}`)
            }
        }
        
        onClicked: (event) => {
            if (event.button === Qt.LeftButton) {
                Hyprland.dispatch(`focuswindow address:${root.windowData.address}`)
                GlobalStates.workspacesOverviewOpen = false
                event.accepted = true
            } else if (event.button === Qt.MiddleButton) {
                Hyprland.dispatch(`closewindow address:${root.windowData.address}`)
                event.accepted = true
            }
        }
    }
}
