import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Keep awake")

    toggled: Idle.inhibit
    icon: toggled ? "kettle" : "coffee"
    mainAction: () => {
        Idle.toggleInhibit()
    }
    altAction: () => {
        Idle.toggleStartInhibited()
    }
    tooltipText: Translation.tr("Keep system awake") + (Persistent.states.idle.startInhibited ? Translation.tr(" (Active on startup)") : "")
}
