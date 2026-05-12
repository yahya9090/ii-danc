pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: overviewRoot
    
    required property int monitorIndex
    required property var panelWindow
    
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
    readonly property var monitorData: HyprlandData.monitors.find(m => m.name === overviewRoot.monitor?.name)
    
    // Now following global overview configuration
    readonly property int rows: Config.options.overview.rows
    readonly property int columns: Config.options.overview.columns
    readonly property int totalWorkspaces: rows * columns
    
    // Constants for cleaner scale
    readonly property real outerRadius: Appearance.rounding.normal
    readonly property real innerRadius: Appearance.rounding.small
    readonly property real workspaceSpacing: 4
    
    // Calculate tile size and scale based on monitor aspect ratio
    readonly property real monitorWidth: Math.max(1, (monitorData?.width ?? 1920) - (monitorData?.reserved?.[0] ?? 0) - (monitorData?.reserved?.[2] ?? 0))
    readonly property real monitorHeight: Math.max(1, (monitorData?.height ?? 1080) - (monitorData?.reserved?.[1] ?? 0) - (monitorData?.reserved?.[3] ?? 0))
    readonly property real monitorRatio: monitorWidth / monitorHeight
    
    readonly property real gridMaxWidth: overviewRoot.width - 4
    readonly property real gridMaxHeight: overviewRoot.height - 4
    
    readonly property real maxTileWidthFromWidth: (gridMaxWidth - (columns - 1) * workspaceSpacing) / columns
    readonly property real maxTileWidthFromHeight: (gridMaxHeight - (rows - 1) * workspaceSpacing) * monitorRatio / rows
    
    readonly property real tileWidth: Math.min(maxTileWidthFromWidth, maxTileWidthFromHeight)
    readonly property real tileHeight: tileWidth / monitorRatio
    
    readonly property real effScale: tileWidth / monitorWidth
    
    // Centering offsets
    readonly property real gridWidth: columns * tileWidth + (columns - 1) * workspaceSpacing
    readonly property real gridHeight: rows * tileHeight + (rows - 1) * workspaceSpacing
    readonly property real horizontalPadding: (overviewRoot.width - gridWidth) / 2
    readonly property real verticalPadding: (overviewRoot.height - gridHeight) / 2
    
    // State for drag and drop
    property int draggingTargetWorkspace: -1
    
    function getWsRow(wsId) {
        return Math.floor((wsId - 1) / columns)
    }

    function getWsColumn(wsId) {
        return (wsId - 1) % columns
    }

    function getXOffset(wsId) {
        return horizontalPadding + (tileWidth + workspaceSpacing) * getWsColumn(wsId)
    }

    function getYOffset(wsId) {
        return verticalPadding + (tileHeight + workspaceSpacing) * getWsRow(wsId)
    }
    
    // Workspace Grid
    Grid {
        id: grid
        x: overviewRoot.horizontalPadding
        y: overviewRoot.verticalPadding
        width: overviewRoot.gridWidth
        height: overviewRoot.gridHeight
        rows: overviewRoot.rows
        columns: overviewRoot.columns
        spacing: overviewRoot.workspaceSpacing
        
        Repeater {
            model: overviewRoot.totalWorkspaces
            
            IslandWorkspaceTile {
                id: tile
                required property int index
                workspaceId: index + 1
                width: overviewRoot.tileWidth
                height: overviewRoot.tileHeight
                isActive: overviewRoot.monitor?.activeWorkspace?.id === workspaceId
                overviewRoot: overviewRoot
                
                // Radius logic matching main overview but with cleaner scale for island
                property bool workspaceAtLeft: index % columns === 0
                property bool workspaceAtRight: index % columns === (columns - 1)
                property bool workspaceAtTop: Math.floor(index / columns) === 0
                property bool workspaceAtBottom: Math.floor(index / columns) === (rows - 1)
                
                topLeftRadius: (workspaceAtLeft && workspaceAtTop) ? overviewRoot.outerRadius : overviewRoot.innerRadius
                topRightRadius: (workspaceAtRight && workspaceAtTop) ? overviewRoot.outerRadius : overviewRoot.innerRadius
                bottomLeftRadius: (workspaceAtLeft && workspaceAtBottom) ? overviewRoot.outerRadius : overviewRoot.innerRadius
                bottomRightRadius: (workspaceAtRight && workspaceAtBottom) ? overviewRoot.outerRadius : overviewRoot.innerRadius
            }
        }
    }

    // Focused workspace indicator
    Rectangle {
        id: focusedWorkspaceIndicator
        property int wsId: overviewRoot.monitor?.activeWorkspace?.id ?? -1
        visible: wsId >= 1 && wsId <= overviewRoot.totalWorkspaces
        
        z: 110 // Above windows to "surround" them correctly
        
        x: overviewRoot.getXOffset(wsId) - 1
        y: overviewRoot.getYOffset(wsId) - 1
        width: overviewRoot.tileWidth + 2
        height: overviewRoot.tileHeight + 2
        
        radius: 10
        color: "transparent"
        border.width: 2 // Thinner border as requested
        border.color: Appearance.colors.colSecondary
        
        Behavior on x {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(overviewRoot)
        }
        Behavior on y {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(overviewRoot)
        }
        Behavior on width {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(overviewRoot)
        }
        Behavior on height {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(overviewRoot)
        }
    }
    
    // Flat Window Repeater
    Item {
        id: windowSpace
        anchors.fill: parent
        z: 100
        
        Repeater {
            model: ScriptModel {
                values: {
                    return ToplevelManager.toplevels.values.filter((toplevel) => {
                        const address = `0x${toplevel.HyprlandToplevel?.address}`
                        const win = HyprlandData.windowByAddress[address]
                        if (!win) return false

                        return win.monitor === overviewRoot.monitorIndex && 
                               win.workspace.id >= 1 && 
                               win.workspace.id <= overviewRoot.totalWorkspaces
                    })
                }
            }
            
            delegate: IslandOverviewWindow {
                required property var modelData
                toplevel: modelData
                windowData: HyprlandData.windowByAddress[`0x${modelData.HyprlandToplevel.address}`]
                monitorData: overviewRoot.monitorData
                scale: overviewRoot.effScale
                overviewRoot: overviewRoot
                xOffset: overviewRoot.getXOffset(windowData.workspace.id)
                yOffset: overviewRoot.getYOffset(windowData.workspace.id)
                workspaceImplicitWidth: overviewRoot.tileWidth
                workspaceImplicitHeight: overviewRoot.tileHeight
                
                workspaceColIndex: overviewRoot.getWsColumn(windowData.workspace.id)
                workspaceRowIndex: overviewRoot.getWsRow(windowData.workspace.id)
                workspaceColumns: overviewRoot.columns
                workspaceRows: overviewRoot.rows
            }
        }
    }
}
