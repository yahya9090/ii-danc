pragma ComponentBehavior: Bound
import QtQml
import QtQuick
import Quickshell.Io
import qs.services
import "../"

NestableObject {
    id: root

    required property string key
    property alias fetching: fetchProc.running
    property bool set
    property var value
    property bool ready: false

    Component.onCompleted: fetch()

    Connections {
        target: HyprlandConfig
        function onReloaded() {
            root.fetch();
        }
    }

    function fetch() {
        fetchProc.command = fetchProc.baseCommand.concat([root.key]);
        fetchProc.running = true;
    }

    function setValue(newValue) {
        HyprlandConfig.set(root.key, newValue)
    }

    function reset() {
        HyprlandConfig.reset(root.key)
    }

    Process {
        id: fetchProc
        property list<string> baseCommand: ["hyprctl", "getoption", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmedText = text.trim();
                if (trimmedText == "no such option" || trimmedText == "")
                    return;
                try {
                    const obj = JSON.parse(trimmedText);
                    const valueKeys = ["int", "float", "str", "data", "custom"];
                    for (const key in obj) {
                        if (key == "option")
                            continue;
                        else if (key == "set")
                            root.set = obj[key];
                        else if (valueKeys.indexOf(key) !== -1) {
                            let val = obj[key];
                            if (key === "custom" && typeof val === "string") {
                                // If it's a "custom" string with multiple values (like "11 11 11 11"), 
                                // try to extract the first part if it's numeric, to help SpinBoxes.
                                const parts = val.trim().split(/\s+/);
                                if (parts.length > 0 && !isNaN(parseFloat(parts[0]))) {
                                    // We keep the original string if it's not a simple number 
                                    // (like colors "rgba(...)"), but for gaps it helps.
                                    // Actually, let's just use the first part if it's a simple number-only string.
                                    if (parts.length > 1 && parts.every(p => !isNaN(parseFloat(p)))) {
                                        val = parseFloat(parts[0]);
                                    }
                                }
                            }
                            root.value = val;
                        }
                    }
                    console.log(`[HyprlandConfigOption] Fetched "${root.key}": ${root.value} (set: ${root.set})`);
                    root.ready = true;
                } catch (e) {
                    console.log(`[HyprlandConfigOption] Failed to fetch option "${root.key}":\n  - Output: ${trimmedText}\n  - Error: ${e}`);
                }
            }
        }
    }
}
