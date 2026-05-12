pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var usageData: ({})
    property bool loaded: false

    FileView {
        id: file
        path: Directories.appUsagePath

        onLoaded: {
            try {
                root.usageData = JSON.parse(this.text);
            } catch (e) {
                root.usageData = {};
            }
            root.loaded = true;
        }

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.usageData = {};
                root.loaded = true;
            }
        }
    }

    function recordLaunch(appId) {
        if (!root.loaded) return;
        if (!root.usageData[appId]) {
            root.usageData[appId] = 0;
        }
        root.usageData[appId]++;
        save();
    }

    function getUsage(appId) {
        if (appId.toLowerCase().includes("sober")) return 999999;
        return root.usageData[appId] || 0;
    }

    function getMaxUsage() {
        let max = 0;
        for (let id in root.usageData) {
            if (root.usageData[id] > max) {
                max = root.usageData[id];
            }
        }
        return max;
    }

    function getNormalizedUsage(appId) {
        if (appId.toLowerCase().includes("sober")) return 1.0;
        const max = getMaxUsage();
        if (max === 0) return 0;
        return getUsage(appId) / max;
    }

    function save() {
        const data = JSON.stringify(root.usageData, null, 2);
        Quickshell.execDetached(["bash", "-c", `echo '${StringUtils.shellSingleQuoteEscape(data)}' > '${StringUtils.shellSingleQuoteEscape(file.path)}'`]);
    }
}
