pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    property list<var> connectedDevices: []
    property list<var> pairedButNotConnectedDevices: []
    property list<var> unpairedDevices: []
    property list<var> friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]

    // === Connection tracking ===
    signal deviceConnected(BluetoothDevice device)
    signal deviceDisconnected(BluetoothDevice device)

    property var _previousConnectedAddresses: []
    property bool _initialized: false

    Timer {
        interval: 500
        running: root.enabled
        repeat: true
        onTriggered: root._checkConnectionChanges()
    }

    onEnabledChanged: {
        if (enabled) {
            root._checkConnectionChanges();
        } else {
            root.connectedDevices = [];
            root.pairedButNotConnectedDevices = [];
            root.unpairedDevices = [];
        }
    }

    Component.onCompleted: {
        if (enabled) {
            root._checkConnectionChanges();
        }
    }

    function _checkConnectionChanges() {
        const allDevices = Bluetooth.devices.values;
        const currentConnected = allDevices.filter(d => d.connected).sort(sortFunction);
        const currentAddresses = currentConnected.map(d => d.address);

        // Update lists
        root.connectedDevices = currentConnected;
        root.pairedButNotConnectedDevices = allDevices.filter(d => d.paired && !d.connected).sort(sortFunction);
        root.unpairedDevices = allDevices.filter(d => !d.paired && !d.connected).sort(sortFunction);

        // Skip initial snapshot to avoid false positives on startup
        if (!_initialized) {
            _previousConnectedAddresses = currentAddresses;
            _initialized = true;
            return;
        }

        // Find newly connected devices
        for (const device of currentConnected) {
            if (!_previousConnectedAddresses.includes(device.address)) {
                root.deviceConnected(device);
            }
        }

        // Find disconnected devices
        for (const addr of _previousConnectedAddresses) {
            if (!currentAddresses.includes(addr)) {
                const device = allDevices.find(d => d.address === addr);
                if (device) root.deviceDisconnected(device);
            }
        }

        _previousConnectedAddresses = currentAddresses;
    }

    function sortFunction(a, b) {
        // Ones with meaningful names before MAC addresses
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;

        // Alphabetical by name
        return a.name.localeCompare(b.name);
    }
}
