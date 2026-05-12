pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.common

Singleton {
    id: root

    property real downloadSpeed: 0
    property real uploadSpeed: 0
    property string downloadSpeedString: "0 B/s"
    property string uploadSpeedString: "0 B/s"
    property real maxSpeed: 100
    property string activeInterface: ""
    property bool monitoring: false

    property real _prevRxBytes: 0
    property real _prevTxBytes: 0
    property bool _hasBaseline: false

    function getSpeedData(bytesPerSecond) {
        let value = bytesPerSecond;
        let sizes = ["B/s", "KB/s", "MB/s", "GB/s"];
        let k = 1024;

        if (Config.options.networking.speedUnit === 1) {
            value = bytesPerSecond * 8;
            sizes = ["bps", "Kbps", "Mbps", "Gbps"];
            k = 1000;
        }

        if (value < 1) return { val: 0, unit: sizes[0] };
        const i = Math.floor(Math.log(value) / Math.log(k));
        return {
            val: value / Math.pow(k, i),
            unit: sizes[i]
        };
    }

    function formatSpeed(bytesPerSecond) {
        const data = root.getSpeedData(bytesPerSecond);
        return parseFloat(data.val.toFixed(1)) + " " + data.unit;
    }

    Connections {
        target: Config.options.networking
        function onSpeedUnitChanged() {
            root.downloadSpeedString = root.formatSpeed(root.downloadSpeed)
            root.uploadSpeedString = root.formatSpeed(root.uploadSpeed)
        }
    }

    function start(): void {
        monitoring = true
        detectInterface.exec(["sh", "-c", "nmcli -t -f DEVICE,STATE d status | grep ':connected' | head -1 | cut -d: -f1"])
    }

    function stop(): void {
        monitoring = false
        pollTimer.running = false
        downloadSpeed = 0
        uploadSpeed = 0
        downloadSpeedString = "0 B/s"
        uploadSpeedString = "0 B/s"
        _hasBaseline = false
    }

    // Detect active wifi interface
    Process {
        id: detectInterface
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: SplitParser {
            onRead: data => {
                root.activeInterface = data.trim()
                if (root.activeInterface.length > 0) {
                    pollTimer.running = true
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            if (root.activeInterface !== "") {
                readStats.exec([
                    "sh", "-c",
                    "cat /sys/class/net/" + root.activeInterface + "/statistics/rx_bytes /sys/class/net/" + root.activeInterface + "/statistics/tx_bytes 2>/dev/null"
                ])
            }
        }
    }

    // read bytes from /sys/class/net/<iface>/statistics/
    Process {
        id: readStats
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n')
                if (lines.length < 2) return
                const rxBytes = parseFloat(lines[0]) || 0
                const txBytes = parseFloat(lines[1]) || 0

                if (root._hasBaseline) {
                    const deltaRx = rxBytes - root._prevRxBytes
                    const deltaTx = txBytes - root._prevTxBytes
                    
                    root.downloadSpeed = Math.max(0, deltaRx)
                    root.uploadSpeed = Math.max(0, deltaTx)
                    
                    root.downloadSpeedString = root.formatSpeed(root.downloadSpeed)
                    root.uploadSpeedString = root.formatSpeed(root.uploadSpeed)
                    
                    // Adjust max (in Mbps for backward compatibility if needed, but here we use bytes)
                    root.maxSpeed = Math.max(root.maxSpeed, root.downloadSpeed, root.uploadSpeed)
                }
                root._prevRxBytes = rxBytes
                root._prevTxBytes = txBytes
                root._hasBaseline = true
            }
        }
    }
}
