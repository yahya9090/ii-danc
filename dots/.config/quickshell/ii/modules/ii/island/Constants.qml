pragma Singleton
import QtQuick
import qs.modules.common

QtObject {
    readonly property int maxWidth: 460
    readonly property int compactWidthOsd: 220
    readonly property int compactWidthNotif: 200
    readonly property int compactWidthBattery: 180
    readonly property int compactWidthMedia: 160
    readonly property int notchClosedWidth: 140
    
    readonly property int expandedWidthHome: 520
    readonly property int expandedWidthMedia: 440
    readonly property int expandedWidthNotif: 400
    readonly property int expandedWidthBattery: 380

    readonly property int notchClosedHeight: 32
    readonly property int osdHeight: 48
    readonly property int expandedHeightHome: 160
    readonly property int expandedHeightMedia: 120
    readonly property int expandedHeightNotif: 100
    readonly property int expandedHeightBattery: 80

    readonly property int launcherWidth: 660
    readonly property int launcherCollapsedWidth: 460
    readonly property int launcherMinHeight: 48
    readonly property int launcherMaxHeight: 500

    readonly property int overviewWidth: 710
    readonly property int overviewHeight: 180

    readonly property real notchClosedTopRadius: 6
    readonly property real notchClosedBottomRadius: 14
    readonly property real notchOpenTopRadius: 20
    readonly property real notchOpenBottomRadius: 24
    
    readonly property real osdTopRadius: 12
    readonly property real osdBottomRadius: 16
    
    readonly property real launcherTopRadius: 16
    readonly property real launcherBottomRadius: 20

    readonly property int peekDurationMs: 3000
    readonly property int batteryPeekMs: 5000
    readonly property int swapDurationMs: 60
    readonly property int osdTimeoutMs: 2000
    readonly property int notifTimeoutMs: 7000
    
    readonly property int mediaArtPeekSize: 24
    readonly property int mediaPeekGap: 8
    readonly property int mediaVizPeekWidth: 20
    
    readonly property bool hoverIdleExpand: true
    readonly property real expandRadius: 24
}
