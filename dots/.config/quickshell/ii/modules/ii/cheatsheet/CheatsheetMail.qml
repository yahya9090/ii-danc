import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property real spacing: 8
    property string activeTab: MailService.currentTab
    property var selectedThread: null

    onActiveTabChanged: {
        MailService.currentTab = activeTab;
        if (activeTab === "compose" || activeTab === "settings") {
            selectedThread = null;
        }
    }

    onSelectedThreadChanged: {
        if (selectedThread) {
            messageBody.text = "Loading content...";
            MailService.getMessageContent(selectedThread.thread, (data) => {
                if (!data) {
                    messageBody.text = "<h3>Error loading content</h3>";
                    return;
                }
                messageBody.text = data;
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colSurfaceContainer
        radius: Appearance.rounding.large
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Navigation
        Rectangle {
            id: headerRow

            Layout.fillHeight: true
            Layout.preferredWidth: 300
            color: Appearance.colors.colSurfaceContainerHigh
            topLeftRadius: Appearance.rounding.large
            topRightRadius: Appearance.rounding.small
            bottomLeftRadius: Appearance.rounding.large
            bottomRightRadius: Appearance.rounding.small

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: root.spacing

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 48

                    RippleButtonWithIcon {
                        Layout.fillWidth: true
                        implicitHeight: 64
                        buttonRadius: Appearance.rounding.full
                        colBackground: root.activeTab === "compose" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        colRipple: Appearance.colors.colSecondaryContainerActive
                        colBackgroundToggled: Appearance.colors.colSecondary
                        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                        colRippleToggled: Appearance.colors.colSecondaryActive
                        scale: down ? 0.95 : hovered ? 1.02 : 1
                        onClicked: {
                            root.activeTab = "compose";
                        }

                        Behavior on scale {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 12

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "edit"
                                    iconSize: 20
                                    color: root.activeTab === "compose" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: Translation.tr("Compose")
                                    font.pixelSize: Appearance.font.pixelSize.huge
                                    font.weight: Font.DemiBold
                                    color: root.activeTab === "compose" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                }

                            }

                        }

                    }

                    VerticalButtonGroup {
                        id: navGroup

                        Layout.fillWidth: true
                        spacing: 4

                        GroupButton {
                            id: inboxBtn

                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            baseHeight: 56
                            bounce: false
                            toggled: root.activeTab === "inbox"
                            onClicked: root.activeTab = "inbox"
                            colBackground: root.activeTab === "inbox" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover
                            scale: down ? 0.95 : hovered ? 1.02 : 1

                            background: Rectangle {
                                color: inboxBtn.color
                                topLeftRadius: inboxBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large
                                topRightRadius: inboxBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large
                                bottomLeftRadius: inboxBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 1 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                bottomRightRadius: inboxBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 1 ? Appearance.rounding.small : Appearance.rounding.verysmall)

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                Behavior on topLeftRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on topRightRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on bottomLeftRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on bottomRightRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                            }

                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                implicitHeight: 56
                                anchors.fill: parent

                                RowLayout {
                                    spacing: 12
                                    anchors.centerIn: parent

                                    MaterialSymbol {
                                        text: "inbox"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: inboxBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "Inbox"
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: inboxBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: inboxBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                }

                            }

                        }

                        GroupButton {
                            id: spamBtn

                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            baseHeight: 56
                            bounce: false
                            toggled: root.activeTab === "spam"
                            onClicked: root.activeTab = "spam"
                            colBackground: root.activeTab === "spam" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover
                            scale: down ? 0.95 : hovered ? 1.02 : 1

                            background: Rectangle {
                                color: spamBtn.color
                                topLeftRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 0 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                topRightRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 0 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                bottomLeftRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 2 ? Appearance.rounding.small : Appearance.rounding.verysmall)
                                bottomRightRadius: spamBtn.toggled ? Appearance.rounding.full : (navGroup.selectedIndex === 2 ? Appearance.rounding.small : Appearance.rounding.verysmall)

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                Behavior on topLeftRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on topRightRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on bottomLeftRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on bottomRightRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                            }

                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                implicitHeight: 56
                                anchors.fill: parent

                                RowLayout {
                                    spacing: 12
                                    anchors.centerIn: parent

                                    MaterialSymbol {
                                        text: "report"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: spamBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "Spam"
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: spamBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: spamBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                }

                            }

                        }

                        GroupButton {
                            id: sentBtn

                            Layout.fillWidth: true
                            Layout.fillHeight: false
                            baseHeight: 56
                            bounce: false
                            toggled: root.activeTab === "sent"
                            onClicked: root.activeTab = "sent"
                            colBackground: root.activeTab === "sent" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colBackgroundToggled: Appearance.colors.colPrimary
                            colBackgroundToggledHover: Appearance.colors.colPrimaryHover
                            scale: down ? 0.95 : hovered ? 1.02 : 1

                            background: Rectangle {
                                color: sentBtn.color
                                topLeftRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.small
                                topRightRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.small
                                bottomLeftRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large
                                bottomRightRadius: sentBtn.toggled ? Appearance.rounding.full : Appearance.rounding.large

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                Behavior on topLeftRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on topRightRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on bottomLeftRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                                Behavior on bottomRightRadius {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                            }

                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                implicitHeight: 56
                                anchors.fill: parent

                                RowLayout {
                                    spacing: 12
                                    anchors.centerIn: parent

                                    MaterialSymbol {
                                        text: "send"
                                        iconSize: Appearance.font.pixelSize.huge
                                        color: sentBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: "Sent"
                                        font.family: Appearance.font.family.main
                                        font.pixelSize: Appearance.font.pixelSize.huge
                                        font.weight: sentBtn.toggled ? Font.DemiBold : Font.Normal
                                        color: sentBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                                    }

                                }

                            }

                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 56
                        color: Appearance.colors.colSurfaceContainerHigh
                        radius: Appearance.rounding.full
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 24
                            spacing: 24

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: "search"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnSurfaceVariant
                            }

                            TextInput {
                                id: searchInput

                                Layout.fillWidth: true
                                text: ""
                                color: Appearance.colors.colOnSurfaceVariant
                                font.pixelSize: Appearance.font.pixelSize.huge
                                font.family: Appearance.font.family.main
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: {
                                    MailService.search(text);
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Search Email"
                                    color: Appearance.colors.colOnSurfaceVariant
                                    font.pixelSize: Appearance.font.pixelSize.huge
                                    font.family: Appearance.font.family.main
                                    visible: searchInput.text.length === 0
                                }

                            }

                        }

                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 56
                            buttonRadius: Appearance.rounding.full
                            colBackground: Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            scale: down ? 0.95 : hovered ? 1.02 : 1
                            onClicked: MailService.sync()

                            contentItem: Item {
                                anchors.fill: parent
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "sync"
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: Appearance.colors.colOnSecondaryContainer
                                }
                            }
                        }

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 56
                            buttonRadius: Appearance.rounding.full
                            colBackground: root.activeTab === "settings" ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
                            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                            colRipple: Appearance.colors.colSecondaryContainerActive
                            colBackgroundToggled: Appearance.colors.colSecondary
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryActive
                            scale: down ? 0.95 : hovered ? 1.02 : 1
                            onClicked: {
                                root.activeTab = "settings";
                            }

                            Behavior on scale {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }

                            contentItem: Item {
                                anchors.fill: parent
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "settings"
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: root.activeTab === "settings" ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
                                }
                            }
                        }
                    }
                }

            }

        }

        // Content Area
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Appearance.colors.colSurfaceContainerHigh
            topLeftRadius: Appearance.rounding.small
            bottomLeftRadius: Appearance.rounding.small
            radius: Appearance.rounding.large
            clip: true

            StackLayout {
                anchors.fill: parent
                currentIndex: {
                    if (root.activeTab === "compose") return 1;
                    if (root.activeTab === "settings") return 2;
                    return 0; // inbox, spam, sent
                }

                // 0: Message List & Viewer
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: emailList

                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4
                        model: MailService.activeMessages
                        clip: true
                        visible: !root.selectedThread

                        ScrollBar.vertical: StyledScrollBar {}

                        PagePlaceholder {
                            anchors.centerIn: parent
                            shown: emailList.count === 0 && !MailService.notmuchAvailable
                            icon: "mail_lock"
                            description: Translation.tr("Notmuch not configured")
                        }

                        PagePlaceholder {
                            anchors.centerIn: parent
                            shown: emailList.count === 0 && MailService.notmuchAvailable
                            icon: "inbox"
                            description: Translation.tr("No messages found")
                        }

                        delegate: RippleButton {
                            width: emailList.width
                            implicitHeight: 80
                            buttonRadius: Appearance.rounding.large
                            colBackground: Appearance.colors.colSurfaceContainerHighest
                            padding: 12
                            onClicked: {
                                root.selectedThread = modelData;
                            }

                            contentItem: ColumnLayout {
                                spacing: 4

                                RowLayout {
                                    StyledText {
                                        text: modelData.authors || ""
                                        font.weight: modelData.tags.indexOf("unread") !== -1 ? Font.Bold : Font.Normal
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        text: modelData.formatted_date || ""
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnSurfaceVariant
                                    }

                                }

                                StyledText {
                                    text: modelData.subject || ""
                                    font.weight: modelData.tags.indexOf("unread") !== -1 ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                            }

                        }

                    }

                    // Message Viewer
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        visible: !!root.selectedThread
                        spacing: 12

                        RowLayout {
                            RippleButton {
                                implicitWidth: 40
                                implicitHeight: 40
                                buttonRadius: Appearance.rounding.full
                                onClicked: root.selectedThread = null

                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "arrow_back"
                                }

                            }

                            StyledText {
                                text: root.selectedThread ? root.selectedThread.subject : ""
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.Bold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Appearance.colors.colOutlineVariant
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Appearance.colors.colSurfaceContainerHigh
                            radius: Appearance.rounding.medium

                            Flickable {
                                id: bodyFlickable
                                anchors.fill: parent
                                anchors.margins: 12
                                contentWidth: width - 24
                                contentHeight: messageBody.implicitHeight
                                clip: true

                                ScrollBar.vertical: StyledScrollBar {}

                                TextEdit {
                                    id: messageBody
                                    width: bodyFlickable.width
                                    readOnly: true
                                    selectByMouse: true
                                    mouseSelectionMode: TextEdit.SelectCharacters
                                    wrapMode: TextEdit.Wrap
                                    textFormat: Text.RichText
                                    onLinkActivated: link => Qt.openUrlExternally(link)
                                    color: Appearance.colors.colOnSurface
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.family: Appearance.font.family.main
                                    text: "Loading content..."
                                    
                                    // Material selection color
                                    selectionColor: Appearance.colors.colPrimaryContainer
                                    selectedTextColor: Appearance.colors.colOnPrimaryContainer
                                }
                            }
                        }
                    }

                }

                // 1: Compose View
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 24
                    spacing: 16

                    StyledText {
                        text: Translation.tr("New Message")
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Bold
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText { text: Translation.tr("To") }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: Appearance.colors.colSurfaceContainer
                            radius: Appearance.rounding.small
                            TextInput {
                                id: toInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                color: Appearance.colors.colOnSurface
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText { text: Translation.tr("Subject") }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: Appearance.colors.colSurfaceContainer
                            radius: Appearance.rounding.small
                            TextInput {
                                id: subjectInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                color: Appearance.colors.colOnSurface
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        StyledText { text: Translation.tr("Message") }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Appearance.colors.colSurfaceContainer
                            radius: Appearance.rounding.small
                            TextEdit {
                                id: bodyInput
                                anchors.fill: parent
                                anchors.margins: 10
                                color: Appearance.colors.colOnSurface
                                wrapMode: TextEdit.Wrap
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                        }
                    }

                    RippleButton {
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: 100
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colPrimary
                        
                        contentItem: StyledText {
                            text: Translation.tr("Send")
                            anchors.centerIn: parent
                            color: Appearance.colors.colOnPrimary
                        }
                        
                        onClicked: {
                            // Sending not yet implemented in service
                            console.log("Send to:", toInput.text, "Subject:", subjectInput.text);
                        }
                    }
                }

                // 2: Settings View
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 24
                    spacing: 24

                    StyledText {
                        text: Translation.tr("Mail Settings")
                        font.pixelSize: Appearance.font.pixelSize.huge
                        font.weight: Font.Bold
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        StyledText {
                            text: Translation.tr("Status")
                            font.weight: Font.Bold
                        }

                        RowLayout {
                            spacing: 12
                            MaterialSymbol {
                                text: MailService.notmuchAvailable ? "check_circle" : "error"
                                color: MailService.notmuchAvailable ? "green" : "red"
                            }
                            StyledText {
                                text: MailService.notmuchAvailable ? Translation.tr("Notmuch is configured and available") : Translation.tr("Notmuch is not configured or not found")
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        StyledText {
                            text: Translation.tr("Actions")
                            font.weight: Font.Bold
                        }

                        RippleButton {
                            implicitWidth: 200
                            implicitHeight: 48
                            buttonRadius: Appearance.rounding.small
                            colBackground: Appearance.colors.colSecondaryContainer
                            
                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialSymbol { text: "sync" }
                                StyledText { text: Translation.tr("Synchronize Mail") }
                            }
                            
                            onClicked: MailService.sync()
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
