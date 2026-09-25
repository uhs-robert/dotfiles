// home/quickshell/.config/quickshell/components/KeyHelp.qml
import QtQuick
import "../theme"
import "../services"
import "KeyHints.js" as KeyHints
import "snes" as Snes

// A popup's full key list, drawn over its content at the same size.
Item {
    id: root

    readonly property var st: Style.for_item(root)

    property string text: ""
    property int tab_count: 0
    property bool has_views: false
    property bool searchable: false
    signal back()

    readonly property var own_entries: KeyHints.parse(root.text).filter(g => !(g.key === "[ ]" && g.desc === "tabs") && !(/^1-\d$/.test(g.key) && g.desc === "select") && !(g.key === "q" && g.desc === "close"))
    readonly property var own_keys: root.own_entries.reduce((keys, g) => keys.concat(g.key.split("/")), [])
    readonly property var general_entries: {
        const e = [];
        if (root.tab_count > 0) {
            e.push({ key: "[ ]", desc: "tabs" });
            e.push({ key: root.tab_count > 1 ? "1-" + Math.min(9, root.tab_count) : "1", desc: "select" });
        }
        if (root.has_views) e.push({ key: "Tab", desc: "views" });
        if (root.searchable) e.push({ key: "/", desc: "search" }, { key: "n/N", desc: "next/prev match" });
        e.push({ key: "Ctrl+h/l", desc: "prev/next module" });
        if (Popups.back_name !== "") e.push({ key: "Backspace", desc: "back to " + Popups.back_name });
        e.push({ key: "?", desc: "help" }, { key: "Esc/Backspace", desc: "back" }, { key: "q", desc: "close" });
        return e.filter(g => root.own_keys.indexOf(g.key) < 0);
    }

    readonly property real key_column: {
        if (root.st.controller !== "") return Math.min(list.width * 0.5, Math.max(key_metrics.height + 2, measure.implicitWidth));
        const h = key_metrics.height + 2;
        let w = 0;
        for (const g of root.own_entries.concat(root.general_entries)) w = Math.max(w, key_metrics.advanceWidth(KeyHints.with_glyphs(g.key)) + root.pad_width(g.key));
        return Math.min(list.width * 0.45, Math.max(h, w + 8));
    }
    readonly property real step: desc_metrics.height * 2
    readonly property real max_y: Math.max(0, flick.contentHeight - flick.height)
    property double last_g_ms: 0

    // Room for a controller button drawn before its key; roughly its sprite plus label.
    function pad_width(key) {
        const b = KeyHints.button(key, root.st.controller);
        return b === "" ? 0 : b.startsWith("dpad") ? 18 : 28 + b.length * 8;
    }

    function scroll_to(y) {
        flick.contentY = Math.max(0, Math.min(root.max_y, y));
    }

    onVisibleChanged: if (visible) flick.contentY = 0

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Question || event.text === "?" || event.key === Qt.Key_Escape || event.key === Qt.Key_Backspace) {
            root.back();
        } else if (event.key === Qt.Key_Q) {
            Popups.close();
        } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            root.scroll_to(flick.contentY + root.step);
        } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            root.scroll_to(flick.contentY - root.step);
        } else if (event.key === Qt.Key_G && (event.modifiers & Qt.ShiftModifier)) {
            root.scroll_to(root.max_y);
        } else if (event.key === Qt.Key_G) {
            const now_ms = Date.now();
            if (now_ms - root.last_g_ms < 500) {
                root.last_g_ms = 0;
                root.scroll_to(0);
            } else {
                root.last_g_ms = now_ms;
            }
        }
        event.accepted = true;
    }

    FontMetrics {
        id: key_metrics
        font.family: root.st.mono_font
        font.pixelSize: root.st.font_size - 5
        font.bold: root.st.mono_font === root.st.font_family
    }

    FontMetrics {
        id: desc_metrics
        font.family: root.st.font_family
        font.pixelSize: root.st.font_size - 3
    }

    // Keeps clicks, hover and wheel off the hidden content underneath.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    // The key column with controller buttons: the button, then the keyboard key it stands for.
    component HelpKeys: Row {
        id: help_keys
        property string key: ""
        readonly property var st: Style.for_item(help_keys)
        readonly property var pad: help_keys.st.controller !== "" ? KeyHints.pad_parts(help_keys.st.controller, help_keys.key) : []
        spacing: 4

        Loader {
            active: help_keys.pad.length > 0
            visible: active
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: ({ snes: snes_keys })[help_keys.st.controller] || null

            Component {
                id: snes_keys
                Snes.SnesKey {
                    parts: help_keys.pad
                    text_color: help_keys.st.text_fg
                    font_family: help_keys.st.font_family
                    font_size: help_keys.st.font_size - 5
                }
            }
        }

        KeyBadge {
            anchors.verticalCenter: parent.verticalCenter
            key: KeyHints.with_glyphs(help_keys.key)
        }
    }

    Column {
        id: measure
        visible: root.st.controller !== ""
        opacity: 0

        Repeater {
            model: root.st.controller !== "" ? root.own_entries.concat(root.general_entries) : []

            HelpKeys {
                required property var modelData
                key: modelData.key
            }
        }
    }

    Component {
        id: help_row_component

        Item {
            id: help_row
            required property var modelData
            readonly property real pad_width: pad_loader.active ? pad_loader.width + 5 : 0
            width: list.width
            height: Math.max(badge_clip.height, desc_text.implicitHeight, pad_loader.height)

            Loader {
                id: pad_loader
                visible: active
                active: KeyHints.controller_parts(help_row.modelData.key, root.st.controller).length > 0
                x: root.pad_width - help_row.pad_width
                y: Math.max(0, (desc_metrics.height - height) / 2)
                source: active ? Qt.resolvedUrl(root.st.controller + "/ControllerKeys.qml") : ""
                onLoaded: item.key = Qt.binding(() => help_row.modelData.key)
            }

            Item {
                id: badge_clip
                x: root.pad_width
                y: Math.max(0, (desc_metrics.height - height) / 2)
                width: root.key_column - x
                height: badge.height
                clip: badge.width > width

                HelpKeys {
                    id: badge
                    key: help_row.modelData.key
                }
            }

            Text {
                id: desc_text
                x: root.key_column + 8
                width: Math.max(0, help_row.width - x)
                text: help_row.modelData.desc
                wrapMode: Text.Wrap
                color: root.st.text_fg
                font.family: root.st.font_family
                font.pixelSize: root.st.font_size - 3
                font.capitalization: root.st.label_caps ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: root.st.label_spacing
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 12
        clip: true
        contentWidth: width
        contentHeight: list.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: flick.width - 6
            spacing: 5

            Repeater {
                model: root.own_entries
                delegate: help_row_component
            }

            Item {
                visible: root.own_entries.length > 0
                width: list.width
                height: 4
            }

            MenuSection {
                label: "General"
            }

            Repeater {
                model: root.general_entries
                delegate: help_row_component
            }
        }
    }

    Rectangle {
        visible: flick.contentHeight > flick.height
        x: flick.x + flick.width - width
        y: flick.y + flick.visibleArea.yPosition * flick.height
        width: 2
        height: flick.visibleArea.heightRatio * flick.height
        color: root.st.text_muted
    }
}
