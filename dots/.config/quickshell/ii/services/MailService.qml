import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import Qt.labs.platform
import qs.modules.common.functions

Singleton {
    id: root

    property bool notmuchAvailable: false
    property var inbox: []
    property var spam: []
    property var sent: []
    property var activeMessages: []
    
    property string currentTab: "inbox"
    onCurrentTabChanged: updateActiveMessages()

    Connections {
        target: Config.options.time
        function onFormatChanged() { fetchMails() }
        function onShortDateFormatChanged() { fetchMails() }
    }

    function formatMailDate(timestamp) {
        const date = new Date(timestamp * 1000);
        const now = new Date();
        const timeFormat = Config.options.time.format || "hh:mm";
        
        if (DateUtils.sameDate(date, now)) {
            return Qt.formatDateTime(date, timeFormat);
        } else {
            // For older dates, use short date format
            // We could also try to be fancy like notmuch, but consistency with the rest of the shell is better
            return Qt.formatDateTime(date, Config.options.time.shortDateFormat || "dd/MM");
        }
    }

    function processMails(mailsJson) {
        try {
            let mails = JSON.parse(mailsJson);
            if (!Array.isArray(mails)) return [];
            return mails.map(m => {
                m.formatted_date = root.formatMailDate(m.timestamp);
                return m;
            });
        } catch (e) {
            console.error("[MailService] Error parsing mails:", e);
            return [];
        }
    }

    // Process for checking notmuch configuration
    Process {
        id: notmuchCheckProcess
        command: ["notmuch", "count"]
        running: true
        onExited: (exitCode) => {
            root.notmuchAvailable = (exitCode === 0);
            if (root.notmuchAvailable) {
                refreshTimer.running = true;
                fetchMails();
            }
        }
    }

    function updateActiveMessages() {
        if (currentTab === "inbox") activeMessages = inbox;
        else if (currentTab === "spam") activeMessages = spam;
        else if (currentTab === "sent") activeMessages = sent;
        else activeMessages = [];
    }

    function fetchMails() {
        if (!notmuchAvailable) return;
        fetchInbox.running = true;
        fetchSpam.running = true;
        fetchSent.running = true;
    }

    Process {
        id: fetchInbox
        command: ["notmuch", "search", "--format=json", "--limit=50", "tag:inbox"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) {
                    root.inbox = root.processMails(this.text);
                    if (root.currentTab === "inbox") root.updateActiveMessages();
                }
            }
        }
    }

    Process {
        id: fetchSpam
        command: ["notmuch", "search", "--format=json", "--limit=50", "tag:spam"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) {
                    root.spam = root.processMails(this.text);
                    if (root.currentTab === "spam") root.updateActiveMessages();
                }
            }
        }
    }

    Process {
        id: fetchSent
        command: ["notmuch", "search", "--format=json", "--limit=50", "tag:sent"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) {
                    root.sent = root.processMails(this.text);
                    if (root.currentTab === "sent") root.updateActiveMessages();
                }
            }
        }
    }

    function search(query) {
        if (!notmuchAvailable || !query) {
            updateActiveMessages();
            return;
        }
        searchProcess.command = ["notmuch", "search", "--format=json", "--limit=50", query];
        searchProcess.running = true;
    }

    Process {
        id: searchProcess
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim()) {
                    root.activeMessages = root.processMails(this.text);
                }
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: Config.options?.resources?.updateInterval ?? 30000
        repeat: true
        onTriggered: fetchMails()
    }

    // Function to get full message content
    function getMessageContent(threadId, callback) {
        if (!notmuchAvailable) return;
        
        const bgColor = Appearance.colors.colSurfaceContainerHigh;
        const fgColor = Appearance.colors.colOnSurface;

        const proc = createMessageProcess.createObject(root, {
            command: ["bash", "-c", "notmuch show --format=raw thread:" + threadId + " | '" + FileUtils.trimFileProtocol(Directories.scriptPath) + "/mail_parser.py' '" + bgColor + "' '" + fgColor + "'"]
        });
        
        proc.finishedCallback = callback;
        proc.running = true;
    }

    Component {
        id: createMessageProcess
        Process {
            id: msgProc
            property var finishedCallback
            stdout: StdioCollector {
                onStreamFinished: {
                    if (msgProc.finishedCallback) {
                        msgProc.finishedCallback(this.text);
                    }
                    msgProc.destroy();
                }
            }
        }
    }

    function sync() {
        // Runs gmi sync then notmuch new
        syncProcess.running = true;
    }

    Process {
        id: syncProcess
        command: ["bash", "-c", "gmi sync && notmuch new"]
        onExited: (code) => {
            fetchMails();
        }
    }
}
