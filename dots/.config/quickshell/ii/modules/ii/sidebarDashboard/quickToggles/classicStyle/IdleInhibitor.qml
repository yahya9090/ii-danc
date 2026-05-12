import qs.modules.common.widgets
import qs.modules.common
import qs.services

QuickToggleButton {
    id: root
    toggled: Idle.inhibit
    buttonIcon: "coffee"
    onClicked: {
        Idle.toggleInhibit()
    }
    altAction: () => {
        Idle.toggleStartInhibited()
    }
    StyledToolTip {
        text: Translation.tr("Keep system awake") + (Persistent.states.idle.startInhibited ? Translation.tr(" (Active on startup)") : "")
    }

}
