pragma Singleton

import qs
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.ii.overlay
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property string query: ""

    function ensurePrefix(prefix) {
        if ([Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.symbols, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch, Config.options.search.prefix.fileSearch].some(i => root.query.startsWith(i))) {
            root.query = prefix + root.query.slice(1);
        } else {
            root.query = prefix + root.query;
        }
    }

    // Load user action scripts from ~/.config/illogical-impulse/actions/
    property var userActionScripts: {
        const actions = [];
        for (let i = 0; i < userActionsFolder.count; i++) {
            const fileName = userActionsFolder.get(i, "fileName");
            const filePath = userActionsFolder.get(i, "filePath");
            if (fileName && filePath) {
                const actionName = fileName.replace(/\.[^/.]+$/, "");
                actions.push({
                    action: actionName,
                    execute: ((path) => (args) => {
                        Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
                    })(FileUtils.trimFileProtocol(filePath.toString()))
                });
            }
        }
        return actions;
    }

    FolderListModel {
        id: userActionsFolder
        folder: Qt.resolvedUrl(Directories.userActions)
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    // Redone list of settings/actions for the launcher
    property var searchActions: [
        {
            action: "wallpaper",
            execute: () => { GlobalStates.wallpaperSelectorOpen = !GlobalStates.wallpaperSelectorOpen; },
            iconName: "image",
            iconType: 0
        },
        {
            action: "dark",
            execute: () => { Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "dark", "--noswitch"]); },
            iconName: "dark_mode",
            iconType: 0
        },
        {
            action: "light",
            execute: () => { Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", "light", "--noswitch"]); },
            iconName: "light_mode",
            iconType: 0
        },
        {
            action: "bar",
            execute: () => { GlobalStates.barOpen = !GlobalStates.barOpen; },
            iconName: "bottom_panel_open",
            iconType: 0
        },
        {
            action: "overlay",
            execute: () => { GlobalStates.overlayOpen = !GlobalStates.overlayOpen; },
            iconName: "layers",
            iconType: 0
        },
        {
            action: "reload",
            execute: () => { Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("shell.qml"), "reload"]); },
            iconName: "refresh",
            iconType: 0
        },
        {
            action: "lock",
            execute: () => { GlobalStates.screenLocked = true; },
            iconName: "lock",
            iconType: 0
        },
        {
            action: "session",
            execute: () => { GlobalStates.sessionOpen = !GlobalStates.sessionOpen; },
            iconName: "power_settings_new",
            iconType: 0
        },
        {
            action: "wipeclipboard",
            execute: () => { Cliphist.wipe(); },
            iconName: "mop",
            iconType: 0
        },
        {
            action: "todo",
            execute: args => { Todo.addTask(args); },
            iconName: "list_alt",
            iconType: 0
        }
    ]

    // Overlay widget toggles
    property var overlayActions: OverlayContext.availableWidgets.map(w => {
        return {
            action: w.identifier,
            execute: () => {
                const identifier = w.identifier;
                if (Persistent.states.overlay.open.includes(identifier)) {
                    Persistent.states.overlay.open = Persistent.states.overlay.open.filter(type => type !== identifier);
                } else {
                    let open = Persistent.states.overlay.open.slice();
                    open.push(identifier);
                    Persistent.states.overlay.open = open;
                }
                GlobalStates.overlayOpen = true;
            },
            iconName: w.materialSymbol,
            iconType: 0
        };
    })

    property var allActions: searchActions.concat(userActionScripts).concat(overlayActions)

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options?.workSafety?.enable?.clipboard ?? false;
        const name = Network.networkName || "";
        const sensitiveNetwork = (Network.ready && StringUtils.stringListContainsSubstring(name.toLowerCase(), Config.options?.workSafety?.triggerCondition?.networkNameKeywords ?? []));
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined) return false;
        const unsafeKeywords = Config.options.workSafety.triggerCondition.linkKeywords;
        return StringUtils.stringListContainsSubstring(entry.toLowerCase(), unsafeKeywords);
    }

    Timer {
        id: nonAppResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            let expr = root.query;
            if (expr.startsWith(Config.options.search.prefix.math)) {
                expr = expr.slice(Config.options.search.prefix.math.length);
            }
            mathProc.calculateExpression(expr);
        }
    }

    onQueryChanged: {
        updateResults();
        nonAppResultsTimer.restart();
        let expr = root.query;
        if (expr.startsWith(Config.options.search.prefix.fileSearch)) {
            expr = expr.slice(Config.options.search.prefix.fileSearch.length);
            fileProc.searchFiles(expr);
        } else {
            root.fileResults = [];
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => { root.mathResult = data; }
        }
    }

    property var fileResults: []
    Process {
        id: fileProc 
        function searchFiles(expr) {
            if (expr.length < 2) return
            fileProc.running = false;
            fileProc.command = ["fd", "-H", "-t", "f", "-t", "d", expr, Config.options.search.fileSearchDirectory || Directories.home]; 
            fileProc.running = true;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const rawResult = this.text;
                const result = rawResult.split('\n');
                result.pop();
                root.fileResults = result;
            }
        }
    }

    property var results: []

    property string cleanedQuery: StringUtils.cleanOnePrefix(query, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.symbols, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])

    function updateResults() {
        if (root.query == "") {
            root.results = [];
            return;
        }

        const query = root.query;

        const mathResultObject = resultComp.createObject(null, {
            name: root.mathResult,
            verb: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'calculate',
            iconType: 0,
            execute: () => { Quickshell.clipboardText = root.mathResult; }
        });

        const fileResultsObjects = root.fileResults.map(entry => {
            return resultComp.createObject(null, {
                type: Translation.tr("File"),
                name: entry,
                verb: Translation.tr("Open"),
                iconName: 'file_open',
                iconType: 0,
                execute: () => { Quickshell.execDetached(["xdg-open", entry]); }
            });
        })

        const appResultObjects = AppSearch.fuzzyQuery(StringUtils.cleanPrefix(query, Config.options.search.prefix.app)).map(entry => {
            return resultComp.createObject(null, {
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: 2,
                verb: Translation.tr("Open"),
                execute: () => {
                    AppUsage.recordLaunch(entry.id);
                    if (!entry.runInTerminal) entry.execute();
                    else {
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: 2,
                        execute: () => {
                            if (!action.runInTerminal) action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            });
        });
        
        const settingsResults = SearchRegistry.getResultsRanked(root.cleanedQuery).map(section => {
            return resultComp.createObject(null, {
                name: section.title,
                comment: section.matchedString !== section.title ? Translation.tr("Section: %1").arg(section.matchedString) : Translation.tr("Settings for %1").arg(section.title),
                verb: Translation.tr("Go"),
                type: Translation.tr("Settings"),
                iconName: "tune",
                iconType: 0,
                execute: () => {
                    GlobalStates.settingsOpen = true;
                    Qt.callLater(() => {
                        GlobalStates.settingsPage = section.title + ":" + root.cleanedQuery;
                    });
                    root.query = "";
                }
            });
        });

        const symbolResults = MaterialSymbolsSearch.fuzzyQuery(StringUtils.cleanPrefix(query, Config.options.search.prefix.symbols)).map(entry => {
            const tabIdx = entry.indexOf("\t");
            const symName = tabIdx >= 0 ? entry.slice(0, tabIdx) : entry;
            return resultComp.createObject(null, {
                rawValue: entry,
                name: symName,
                iconName: symName,
                iconType: 0,
                verb: Translation.tr("Copy"),
                type: Translation.tr("Symbol"),
                execute: () => { Quickshell.clipboardText = symName; }
            });
        });

        const commandResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            verb: Translation.tr("Run"),
            type: Translation.tr("Command"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'terminal',
            iconType: 0,
            execute: () => {
                let cleanedCommand = query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                Quickshell.execDetached(["bash", "-c", cleanedCommand]);
            }
        });

        const webSearchResultObject = resultComp.createObject(null, {
            name: StringUtils.cleanPrefix(query, Config.options.search.prefix.webSearch),
            verb: Translation.tr("Search"),
            type: Translation.tr("Web search"),
            iconName: 'travel_explore',
            iconType: 0,
            execute: () => {
                let queryStr = StringUtils.cleanPrefix(query, Config.options.search.prefix.webSearch);
                let url = Config.options.search.engineBaseUrl + queryStr;
                for (let site of Config.options.search.excludedSites) { url += ` -site:${site}`; }
                Qt.openUrlExternally(url);
            }
        });

        const launcherActionObjects = root.allActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            const queryLower = query.toLowerCase();
            if (actionString.startsWith(queryLower) || queryLower.startsWith(actionString)) {
                return resultComp.createObject(null, {
                    name: queryLower.startsWith(actionString) ? query : actionString,
                    verb: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    iconName: action.iconName || 'settings_suggest',
                    iconType: action.iconType ?? 0,
                    execute: () => { action.execute(query.split(" ").slice(1).join(" ")); }
                });
            }
            return null;
        }).filter(Boolean);

        let result = [];
        const startsWithNumber = /^\d/.test(query);
        const startsWithMathPrefix = query.startsWith(Config.options.search.prefix.math);
        const startsWithShellCommandPrefix = query.startsWith(Config.options.search.prefix.shellCommand);
        const startsWithWebSearchPrefix = query.startsWith(Config.options.search.prefix.webSearch);
        const startsWithClipboardPrefix = query.startsWith(Config.options.search.prefix.clipboard);
        const startsWithEmojiPrefix = query.startsWith(Config.options.search.prefix.emojis);
        const startsWithSymbolPrefix = query.startsWith(Config.options.search.prefix.symbols);

        if (startsWithClipboardPrefix) {
            const searchString = StringUtils.cleanPrefix(query, Config.options.search.prefix.clipboard);
            result = Cliphist.fuzzyQuery(searchString).map((entry, index, array) => {
                const mightBlurImage = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
                let shouldBlurImage = mightBlurImage;
                if (mightBlurImage) {
                    shouldBlurImage = shouldBlurImage && (root.containsUnsafeLink(array[index - 1]) || root.containsUnsafeLink(array[index + 1]));
                }
                const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    verb: "",
                    type: type,
                    execute: () => { Cliphist.copy(entry); },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Copy"),
                            iconName: "content_copy",
                            iconType: 0,
                            execute: () => { Cliphist.copy(entry); }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Delete"),
                            iconName: "delete",
                            iconType: 0,
                            execute: () => { Cliphist.deleteEntry(entry); }
                        })],
                    blurImage: shouldBlurImage
                });
            }).filter(Boolean);
        } else if (startsWithEmojiPrefix) {
            const searchString = StringUtils.cleanPrefix(query, Config.options.search.prefix.emojis);
            result = Emojis.fuzzyQuery(searchString).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: 1,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Emoji"),
                    execute: () => { Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1]; },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Copy"),
                            iconName: "content_copy",
                            iconType: 0,
                            execute: () => { Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1]; }
                        })]
                });
            }).filter(Boolean);
        } else if (startsWithSymbolPrefix) {
            result = symbolResults;
        } else {
            if (startsWithNumber || startsWithMathPrefix) result.push(mathResultObject);
            else if (startsWithShellCommandPrefix) result.push(commandResultObject);
            else if (startsWithWebSearchPrefix) result.push(webSearchResultObject);

            result = result.concat(fileResultsObjects);
            result = result.concat(appResultObjects);
            result = result.concat(settingsResults);
            result = result.concat(launcherActionObjects);

            if (Config.options.search.prefix.showDefaultActionsWithoutPrefix) {
                if (!startsWithShellCommandPrefix) result.push(commandResultObject);
                if (!startsWithNumber && !startsWithMathPrefix) result.push(mathResultObject);
                if (!startsWithWebSearchPrefix) result.push(webSearchResultObject);
            }
        }

        root.results = result;
    }

    onMathResultChanged: updateResults()
    onFileResultsChanged: updateResults()

    Connections {
        target: Cliphist
        function onEntriesChanged() { updateResults() }
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}
