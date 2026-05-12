pragma Singleton

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property string hyprlandConfigPath: Directories.home.replace("file://", "") + "/.local/share/ii-vynx/hyprland.conf"
    
    Process {
        id: configWriter
        
        running: false
        property string pendingCommand: ""
        command: ["bash", "-c", pendingCommand]

        onExited: (exitCode, exitStatus) => {
            // NOTE: This will not work bc we are running it detached
            if (exitCode === 1) {
                Quickshell.execDetached(["notify-send", Translation.tr("Couldn't change the setting"), Translation.tr("Make sure you have vynx-cli installed"), "-a", "Shell"])
            }
        }
    }

    function changeKey(key, value) {
        HyprlandConfig.set(key, value)
    }

    function changeAnimation(animName, style) {
        // We'll need to handle animations specifically if HyprlandConfig doesn't yet,
        // but for now, let's at least stop it from using the broken vynx-cli.
        // HyprlandConfig currently handles key/value pairs.
        // If animName is 'workspaces', it might be a special case.
        console.log("[HyprlandSettings] changeAnimation requested:", animName, style)
    }

    function setLayout(layout) {
        if (layout !== "default" && layout !== "scrolling" && layout !== "dwindle" && layout !== "monocle" && layout !== "master") return
        // console.log("[HyprlandSettings] Setting layout to", layout)
        HyprlandConfig.set("general:layout", layout)
    }

    function setRounding(rounding) {
        HyprlandConfig.set("decoration:rounding", rounding)
    }

    Timer {
        id: loadTimer
        interval: 100
        repeat: true
        onTriggered: {
            if (Config.ready && Persistent.ready) {
                if (Config.options.appearance.sharpMode) {
                    setRounding(0)
                }
                
                if (Persistent.states.hyprland.layout !== "default" && Persistent.states.hyprland.layout !== "") {
                    setLayout(Persistent.states.hyprland.layout)
                }
                stop()
            }
        }
    }

    function load() {
        loadTimer.start()
    }
}