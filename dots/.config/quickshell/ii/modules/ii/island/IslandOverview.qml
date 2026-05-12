pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.island

Item {
    id: root
    
    property int monitorIndex
    property var panelWindow
    
    implicitWidth: Constants.overviewWidth
    implicitHeight: Constants.overviewHeight
    
    IslandWorkspacesOverview {
        id: overviewWidget
        anchors.fill: parent
        panelWindow: root.panelWindow
        monitorIndex: root.monitorIndex
    }
}
