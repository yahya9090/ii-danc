pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models
import qs.modules.ii.island

RippleButton {
    id: root

    required property var entry
    property string query: ""
    property bool selected: (root.hovered || root.focus)

    signal actionExecuted(string actionName)

    // Match overview's padding/margins
    property int buttonHorizontalPadding: 12
    property int buttonVerticalPadding: 6
    
    implicitHeight: row.implicitHeight + buttonVerticalPadding * 2
    implicitWidth: row.implicitWidth + buttonHorizontalPadding * 2
    
    buttonRadius: 12
    
    // Consistency with overview/SearchItem.qml
    colBackground: root.down ? Appearance.colors.colPrimaryContainerActive
        : selected ? Appearance.colors.colPrimaryContainer
        : "transparent"
    colBackgroundHover: Appearance.colors.colPrimaryContainer
    colRipple: Appearance.colors.colPrimaryContainerActive
    
    readonly property color fgColor: selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSurface
    readonly property color subfgColor: selected ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext

    function highlight(text, q) {
        if (!q || q.length === 0) return StringUtils.escapeHtml(text);
        const tl = text.toLowerCase();
        const ql = q.toLowerCase();
        let out = "";
        let qi = 0;
        
        const highlightColor = Appearance.colors.colPrimary;
        const tag = `<font color="${highlightColor}"><b>`;
        const endTag = "</b></font>";
        
        for (let i = 0; i < text.length; i++) {
            const ch = StringUtils.escapeHtml(text[i]);
            if (qi < ql.length && tl[i] === ql[qi]) {
                out += tag + ch + endTag;
                qi++;
            } else {
                out += ch;
            }
        }
        return out;
    }

    background {
        anchors.fill: root
        anchors.leftMargin: 4
        anchors.rightMargin: 4
    }

    contentItem: RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        // ── Icon ─────────────────────────────────────────────────────────────
        Item {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32

            Loader {
                anchors.centerIn: parent
                width: 32
                height: 32
                sourceComponent: {
                    if (!root.entry) return null;
                    switch (root.entry.iconType) {
                        case LauncherSearchResult.IconType.System:   return sysIconComp;
                        case LauncherSearchResult.IconType.Material: return matIconComp;
                        case LauncherSearchResult.IconType.Text:     return textIconComp;
                        default:         return null;
                    }
                }
            }
        }

        Component {
            id: sysIconComp
            IconImage {
                source: Quickshell.iconPath(root.entry?.iconName ?? "", "application-x-executable")
                anchors.fill: parent
            }
        }
        Component {
            id: matIconComp
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.entry?.iconName ?? ""
                iconSize: 30 // Matched with overview
                color: root.fgColor
            }
        }
        Component {
            id: textIconComp
            StyledText {
                anchors.centerIn: parent
                text: root.entry?.iconName ?? ""
                font.pixelSize: 22
                color: root.fgColor
            }
        }

        // ── Labels ───────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            StyledText {
                visible: root.entry?.type && root.entry.type !== Translation.tr("App")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.subfgColor
                text: root.entry?.type ?? ""
                opacity: 0.8
            }

            StyledText {
                Layout.fillWidth: true
                textFormat: Text.StyledText
                font.pixelSize: Appearance.font.pixelSize.normal
                color: root.fgColor
                elide: Text.ElideRight
                text: root.highlight(root.entry?.name ?? "", root.query)
            }
        }

        // ── Verb / Actions ──────────────────────────────────────────────────
        StyledText {
            visible: root.selected && (root.entry?.actions ?? []).length === 0
            font.pixelSize: Appearance.font.pixelSize.normal
            color: root.subfgColor
            text: root.entry?.verb ?? ""
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6
            // Always visible for clipboard entries or on hover/select
            visible: root.selected || root.entry.type.startsWith("#") || root.entry.type === Translation.tr("Emoji")
            Repeater {
                model: (root.entry?.actions ?? []).slice(0, 4)
                delegate: RippleButton {
                    id: actionButton
                    required property var modelData
                    property var iconType: modelData.iconType
                    property string iconName: modelData.iconName ?? ""
                    implicitHeight: 30
                    implicitWidth: 30

                    colBackground: "transparent"
                    colBackgroundHover: root.selected ? ColorUtils.applyAlpha(Appearance.colors.colOnPrimaryContainer, 0.15) : Appearance.colors.colSecondaryContainerHover
                    colRipple: root.selected ? ColorUtils.applyAlpha(Appearance.colors.colOnPrimaryContainer, 0.25) : Appearance.colors.colSecondaryContainerActive
                    buttonRadius: 8

                    contentItem: Item {
                        anchors.centerIn: parent
                        Loader {
                            anchors.centerIn: parent
                            active: actionButton.iconType === LauncherSearchResult.IconType.Material || actionButton.iconName === ""
                            sourceComponent: MaterialSymbol {
                                text: actionButton.iconName || "video_settings" // Matched with overview
                                font.pixelSize: Appearance.font.pixelSize.hugeass
                                color: root.fgColor
                            }
                        }
                        Loader {
                            anchors.centerIn: parent
                            active: actionButton.iconType === LauncherSearchResult.IconType.System && actionButton.iconName !== ""
                            sourceComponent: IconImage {
                                source: Quickshell.iconPath(actionButton.iconName)
                                implicitSize: 20 // Matched with overview
                            }
                        }
                    }

                    onClicked: {
                        modelData.execute();
                        root.actionExecuted(modelData.name);
                    }
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked();
            event.accepted = true;
        }
    }
}
