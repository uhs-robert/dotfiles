// home/quickshell/.config/quickshell/picker/HyprvimPrompt.qml
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../components"
import "../theme"
import "../services"
import "Fuzzy.js" as Fuzzy

// HyprVim's prompt bar over its `hyprvim_prompt` IPC target, docked at the bottom in the active style.
// HyprVim stays authoritative: the bar only edits a line, then writes it to result_path and dispatches the callback.
Popup {
    id: root

    popup_name: "hyprvim_prompt"
    size_class: "large"
    dock_bottom: true
    anim_scale: 0.3
    title: String(root.spec.title || "Prompt").toUpperCase()
    key_help: ""
    footer_hint: root.is_output ? "j/k scroll · Ctrl+d/u half page · gg/G top/bottom · Enter/Esc/q close" : "Enter run · Tab/Shift+Tab complete · Up/Down history · Esc " + (root.menu_shown ? "hide menu" : "cancel")

    readonly property int max_output: 100000
    readonly property int max_items: 200

    property var spec: ({})
    // True from open until the callback is dispatched; the callback fires exactly once per spec.
    property bool session: false
    // [text or null, result_path, callback] waiting for the bar to unmap, as the terminal's exit would.
    property var pending: null
    readonly property bool is_open: Popups.open_name === root.popup_name
    readonly property bool is_output: root.spec.kind === "output"
    readonly property real screen_height: root.screen ? root.screen.height : 1080
    readonly property real row_height: Style.px(26)
    readonly property real input_height: Style.px(30)

    // Tab cycling previews candidates in the line; the menu keeps ranking what was typed before it.
    property var cycle_base: null
    property int selected: -1
    property bool menu_hidden: false
    property bool applying: false
    property int history_index: -1
    property string draft: ""
    property string output_text: ""
    // First visible menu row; the menu is a fixed window of slots over items.
    property int menu_top: 0
    // Latched per prompt once shown, so the layer surface keeps one height while typing.
    property bool menu_reserved: false
    property bool hint_reserved: false

    // Keyed "cmd|pos|prev_args"; a source runs once per key per prompt.
    property var source_cache: ({})
    property var source_queue: []
    property var shell_items: null
    // Last source and query with every match, so a query that only grew filters those instead of the whole source.
    readonly property var memo: ({ key: "", cur: "", matched: [] })

    readonly property string query_text: root.cycle_base !== null ? root.cycle_base : input.text
    readonly property var ctx: root.context_of(root.query_text)
    readonly property var arg_spec: root.ctx.kind === "arg" ? root.arg_spec_for(root.ctx.cmd, root.ctx.pos) : null
    readonly property string hint: root.arg_spec && root.arg_spec.hint ? root.arg_spec.hint : ""
    readonly property bool loading: root.ctx.kind === "shell" && root.shell_items === null || !!root.arg_spec && !!root.arg_spec.source && root.source_cache[root.source_key()] === undefined
    readonly property var items: root.candidates(root.ctx, root.source_cache, root.shell_items)
    readonly property bool menu_shown: !root.is_output && !root.menu_hidden && root.items.length > 0 && (root.query_text !== "" || root.cycle_base !== null)
    readonly property int menu_slots: Math.min(10, Math.max(3, Math.floor(root.screen_height * 0.35 / root.row_height)))
    readonly property int menu_rows: root.menu_shown ? Math.min(root.items.length - root.menu_top, root.menu_slots) : 0
    readonly property bool hint_shown: !root.is_output && (root.hint !== "" || root.loading)
    readonly property real output_height: Math.min(output_view.contentHeight + 8, Math.round(root.screen_height * 0.45))

    body_height: root.is_output
        ? output_label.height + 8 + root.output_height + 24
        : root.input_height + (root.hint_reserved ? hint_text.height + 6 : 0) + (root.menu_reserved ? root.menu_slots * root.row_height + 8 : 0) + 24

    onCtxChanged: root.request_sources()
    onItemsChanged: {
        root.menu_top = 0;
        root.reveal_selected();
    }
    onMenu_shownChanged: if (root.menu_shown) root.menu_reserved = true
    onHint_shownChanged: if (root.hint_shown) root.hint_reserved = true
    onIs_openChanged: {
        if (root.is_open) Qt.callLater(root.focus_body);
        else if (root.session) root.finish(null);
    }
    onVisibleChanged: if (!visible) root.flush()
    // A config reload mid-prompt must still answer, or HyprVim never restores the mode.
    Component.onDestruction: {
        root.finish(null);
        root.flush();
    }

    IpcHandler {
        target: "hyprvim_prompt"

        // Returns "ok" once the prompt is shown; HyprVim falls back to its terminal bar on anything else.
        function open(path: string): string {
            return root.open_spec(path);
        }

        function close(): void {
            if (root.session) root.finish(null);
        }
    }

    FileView {
        id: spec_file
        blockLoading: true
        printErrors: false
    }

    FileView {
        id: output_file
        blockLoading: true
        printErrors: false
    }

    Process {
        id: source_proc
        property string key: ""
        stdout: StdioCollector {
            // a stale result can still arrive right after finish() stops the process
            onStreamFinished: {
                if (!root.session) return;
                const next = Object.assign({}, root.source_cache);
                next[source_proc.key] = root.parse_source(text);
                root.source_cache = next;
                root.run_next_source();
            }
        }
    }

    Process {
        id: shell_proc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.session) return;
                root.shell_items = text.split("\n").filter(l => l !== "").map(l => ({ label: l, description: "", insert: l + " " }));
            }
        }
    }

    function open_spec(path) {
        if (root.session) root.finish(null);
        root.flush();
        spec_file.path = path;
        let parsed;
        try {
            parsed = JSON.parse(spec_file.text());
        } catch (e) {
            console.warn("hyprvim_prompt: invalid spec (" + e + ")");
            return "invalid";
        }
        if (!parsed || !parsed.callback) return "invalid";
        root.spec = parsed;
        root.session = true;
        root.cycle_base = null;
        root.selected = -1;
        root.menu_hidden = false;
        root.history_index = -1;
        root.draft = "";
        root.source_cache = {};
        root.source_queue = [];
        root.shell_items = null;
        root.output_text = "";
        root.menu_top = 0;
        root.menu_reserved = false;
        root.hint_reserved = false;
        root.memo.key = "";
        root.memo.matched = [];
        if (root.is_output) {
            output_file.path = parsed.output_path || "";
            const text = output_file.text() || "";
            root.output_text = text.length > root.max_output ? text.slice(0, root.max_output) + "\n[output truncated]" : text.replace(/\n+$/, "");
            output_view.contentY = 0;
        }
        root.set_text(parsed.text || "");
        const mon = Hyprland.focusedMonitor;
        const screen = (mon && Quickshell.screens.find(s => s.name === mon.name)) || Quickshell.screens[0];
        Popups.open(root.popup_name, null, Theme.bg_mantle, screen ? screen.name : "");
        return "ok";
    }

    // Cancel is result null: HyprVim reads a missing result file as no input.
    function finish(result) {
        if (!root.session) return;
        root.session = false;
        root.source_queue = [];
        if (source_proc.running) source_proc.running = false;
        if (shell_proc.running) shell_proc.running = false;
        root.pending = [result, root.spec.result_path || "", root.spec.callback];
        if (root.is_open) Popups.close();
        if (!root.visible) root.flush();
    }

    function flush() {
        const p = root.pending;
        if (!p) return;
        root.pending = null;
        if (p[0] !== null && p[1] !== "") Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" > \"$2\"; exec hyprctl dispatch \"$3\"", "sh", p[0], p[1], p[2]]);
        else Quickshell.execDetached(["hyprctl", "dispatch", p[2]]);
    }

    function focus_body() {
        if (!root.is_open) return;
        if (root.is_output) output_scope.forceActiveFocus();
        else input.forceActiveFocus();
    }

    function set_text(text) {
        root.applying = true;
        input.text = text;
        input.cursorPosition = text.length;
        root.applying = false;
    }

    // What the cursor is completing: a command name, a command's Nth argument, or a shell command after `!`.
    function context_of(line) {
        let head = "";
        let seg = line;
        if (root.spec.chain && !/^(?:!|silent\s+!|%?s\/)/.test(line)) {
            const cut = line.lastIndexOf("|");
            if (cut >= 0) {
                const rest = line.slice(cut + 1);
                const lead = rest.match(/^\s*/)[0];
                head = line.slice(0, cut + 1) + lead;
                seg = rest.slice(lead.length);
            }
        }
        const shell = seg.match(/^((?:silent\s+)?!)(\S*)$/);
        if (shell) return root.spec.shell_source ? { kind: "shell", head: head + shell[1], cur: shell[2] } : { kind: "none" };
        if (/^(?:silent\s+)?!/.test(seg) || /^%?s\//.test(seg)) return { kind: "none" };
        const space = seg.indexOf(" ");
        if (space < 0) return { kind: "command", head: head, cur: seg };
        const words = seg.slice(space + 1).split(/\s+/).filter(w => w !== "");
        const trailing = /\s$/.test(seg);
        const cur = trailing ? "" : words[words.length - 1] || "";
        const pos = trailing ? words.length + 1 : words.length;
        return { kind: "arg", head: head + seg.slice(0, seg.length - cur.length), cmd: seg.slice(0, space), pos: pos, cur: cur, prev: words.slice(0, pos - 1).join(" ") };
    }

    function canonical(cmd) {
        const args = root.spec.args || {};
        if (args[cmd]) return cmd;
        const entry = (root.spec.completions || []).find(c => (c.aliases || []).indexOf(cmd) >= 0);
        return entry ? entry.name : cmd;
    }

    function arg_spec_for(cmd, pos) {
        const positions = (root.spec.args || {})[root.canonical(cmd)];
        return positions && pos >= 1 && pos <= positions.length ? positions[pos - 1] : null;
    }

    function source_key() {
        return root.ctx.kind === "arg" ? root.canonical(root.ctx.cmd) + "|" + root.ctx.pos + "|" + root.ctx.prev : "";
    }

    function request_sources() {
        if (!root.session || root.is_output) return;
        if (root.ctx.kind === "shell" && root.shell_items === null && !shell_proc.running) {
            shell_proc.command = ["bash", "-c", root.spec.shell_source];
            shell_proc.running = true;
        }
        const spec = root.arg_spec;
        if (!spec || !spec.source) return;
        const key = root.source_key();
        if (root.source_cache[key] !== undefined || root.source_queue.some(q => q.key === key)) return;
        root.source_queue = root.source_queue.concat([{ key: key, source: spec.source, prev: root.ctx.prev }]);
        if (!source_proc.running) root.run_next_source();
    }

    function run_next_source() {
        if (root.source_queue.length === 0) return;
        const next = root.source_queue[0];
        root.source_queue = root.source_queue.slice(1);
        source_proc.key = next.key;
        source_proc.environment = { HV_ARGS: next.prev };
        source_proc.command = ["bash", "-c", next.source];
        source_proc.running = true;
    }

    // "value<TAB>description[<TAB>insert]" lines; a line with no value is not a candidate.
    function parse_source(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const f = line.split("\t");
            const value = f[0].trim();
            if (value === "") continue;
            out.push({ label: value, description: f[1] || "", insert: (f[2] || value) + " " });
        }
        return out;
    }

    // Matching is monotonic: whatever matches a longer query also matched its prefix.
    function narrowed_base(key, list, cur) {
        const m = root.memo;
        const base = m.key === key && cur.startsWith(m.cur) ? m.matched : list;
        m.key = key;
        m.cur = cur;
        return base;
    }

    function rank(key, list, query) {
        const terms = Fuzzy.terms_of(query);
        const base = root.narrowed_base(key, list, query);
        if (terms.length === 0) {
            root.memo.matched = base;
            return base.slice(0, root.max_items).map(item => ({ item: item, positions: [] }));
        }
        const out = [];
        const matched = [];
        for (const item of base) {
            const m = Fuzzy.score_item(terms, item);
            if (!m) continue;
            out.push({ item: item, positions: m.positions, score: m.score });
            matched.push(item);
        }
        root.memo.matched = matched;
        out.sort((a, b) => b.score - a.score || a.item.label.length - b.item.label.length);
        return out.slice(0, root.max_items);
    }

    function candidates(ctx, cache, shell_items) {
        if (!root.session || root.is_output) return [];
        if (ctx.kind === "command") {
            const list = (root.spec.completions || []).map(c => ({ label: c.name, description: c.desc || "", keywords: c.aliases || [], insert: c.name + (c.takes_args ? " " : "") }));
            return root.rank("command", list, ctx.cur);
        }
        if (ctx.kind === "shell") {
            const base = root.narrowed_base("shell|" + (shell_items !== null), shell_items || [], ctx.cur);
            const list = base.filter(i => i.label.startsWith(ctx.cur));
            root.memo.matched = list;
            return list.slice(0, root.max_items).map(item => ({ item: item, positions: [...Array(ctx.cur.length).keys()] }));
        }
        if (ctx.kind !== "arg") return [];
        const spec = root.arg_spec_for(ctx.cmd, ctx.pos);
        if (!spec) return [];
        const key = root.canonical(ctx.cmd) + "|" + ctx.pos + "|" + ctx.prev;
        const sourced = spec.source ? cache[key] : undefined;
        let list = (spec.values || []).map(v => ({ label: v[0], description: v[1] || "", insert: v[0] + " " }));
        if (sourced) list = list.concat(sourced);
        return root.rank("arg|" + key + "|" + (sourced !== undefined), list, ctx.cur);
    }

    function apply(index) {
        const entry = root.items[index];
        if (!entry) return;
        root.set_text(root.ctx.head + entry.item.insert);
    }

    function cycle(delta) {
        const n = root.items.length;
        if (n === 0) return;
        if (root.cycle_base === null) {
            if (n === 1) {
                root.menu_hidden = false;
                root.apply(0);
                return;
            }
            root.cycle_base = input.text;
            root.menu_hidden = false;
            root.selected = delta > 0 ? 0 : n - 1;
        } else {
            root.selected = ((root.selected + delta) % n + n) % n;
        }
        root.reveal_selected();
        root.apply(root.selected);
    }

    function reveal_selected() {
        if (root.selected < 0) return;
        if (root.selected < root.menu_top) root.menu_top = root.selected;
        else if (root.selected >= root.menu_top + root.menu_slots) root.menu_top = root.selected - root.menu_slots + 1;
    }

    function scroll_menu(delta) {
        root.menu_top = Math.max(0, Math.min(root.items.length - root.menu_slots, root.menu_top + delta));
    }

    function recall(delta) {
        const history = root.spec.history || [];
        if (history.length === 0) return;
        if (root.history_index === -1) {
            if (delta > 0) return;
            root.draft = input.text;
            root.history_index = history.length;
        }
        const next = root.history_index + delta;
        if (next < 0) return;
        root.cycle_base = null;
        root.selected = -1;
        root.menu_hidden = true;
        if (next >= history.length) {
            root.history_index = -1;
            root.set_text(root.draft);
        } else {
            root.history_index = next;
            root.set_text(history[next]);
        }
    }

    function delete_word() {
        const pos = input.cursorPosition;
        const before = input.text.slice(0, pos).replace(/\S+\s*$|\s+$/, "");
        input.text = before + input.text.slice(pos);
        input.cursorPosition = before.length;
    }

    function handle_input_key(event) {
        const ctrl = event.modifiers & Qt.ControlModifier;
        const k = event.key;
        if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            root.finish(input.text);
        } else if (k === Qt.Key_Escape) {
            if (root.menu_shown) {
                root.menu_hidden = true;
                root.cycle_base = null;
                root.selected = -1;
            } else {
                root.finish(null);
            }
        } else if (k === Qt.Key_Tab) {
            root.cycle(1);
        } else if (k === Qt.Key_Backtab) {
            root.cycle(-1);
        } else if (k === Qt.Key_Up || (ctrl && k === Qt.Key_P)) {
            root.recall(-1);
        } else if (k === Qt.Key_Down || (ctrl && k === Qt.Key_N)) {
            root.recall(1);
        } else if (ctrl && k === Qt.Key_U) {
            input.text = input.text.slice(input.cursorPosition);
            input.cursorPosition = 0;
        } else if (ctrl && k === Qt.Key_W) {
            root.delete_word();
        } else {
            return;
        }
        event.accepted = true;
    }

    function scroll_output(dy) {
        const max = Math.max(0, output_view.contentHeight - output_view.height);
        output_view.contentY = Math.max(0, Math.min(max, output_view.contentY + dy));
    }

    onJump_first: output_view.contentY = 0
    onJump_last: root.scroll_output(output_view.contentHeight)
    jumps_enabled: root.is_output

    Item {
        id: body
        anchors.fill: parent
        anchors.margins: 12

        FocusScope {
            id: input_scope
            anchors.fill: parent
            visible: !root.is_output
            focus: !root.is_output

            // Fixed slots over a window of items: typing rebinds rows instead of recreating them.
            Column {
                id: menu
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: input_bar.top
                anchors.bottomMargin: 6 + (root.hint_reserved ? hint_text.height + 6 : 0)
                visible: root.menu_shown

                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => root.scroll_menu(event.angleDelta.y < 0 ? 1 : -1)
                }

                Repeater {
                    model: root.menu_reserved ? root.menu_slots : 0

                    delegate: Item {
                        id: menu_slot
                        required property int index
                        width: menu.width
                        height: root.row_height
                        visible: menu_slot.index < root.menu_rows

                        MenuRow {
                            id: row
                            readonly property int item_index: root.menu_top + menu_slot.index
                            readonly property var entry: root.items[row.item_index] || ({ item: { label: "", description: "" }, positions: [] })

                            width: menu.width
                            height: root.row_height - 2
                            selected: row.item_index === root.selected

                            Text {
                                id: row_label
                                x: 8 + row.inset
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, Math.max(Style.px(160), menu.width * 0.3))
                                elide: Text.ElideRight
                                textFormat: Text.StyledText
                                text: Fuzzy.highlight(row.entry.item.label, row.entry.positions, String(row.fg(root.st.text_accent)))
                                color: row.fg(root.st.text_fg)
                                font.family: root.st.mono_font
                                font.pixelSize: root.st.font_size - 1
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8 + row.inset + Math.max(Style.px(160), menu.width * 0.3) + 16
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: row.entry.item.description
                                color: row.fg(root.st.text_muted)
                                font.family: root.st.font_family
                                font.pixelSize: root.st.font_size - 3
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.apply(row.item_index);
                                    root.cycle_base = null;
                                    root.selected = -1;
                                    input.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            Text {
                id: hint_text
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: input_bar.top
                anchors.bottomMargin: 6
                visible: root.hint_shown
                elide: Text.ElideRight
                text: root.loading && root.hint === "" ? "loading..." : ":" + (root.ctx.cmd || "") + " arg " + (root.ctx.pos || "") + ": " + root.hint + (root.loading ? "  (loading...)" : "")
                color: root.st.text_muted
                font.family: root.st.font_family
                font.pixelSize: root.st.font_size - 3
            }

            Rectangle {
                id: input_bar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.input_height
                radius: Style.radius(4)
                color: Theme.bg_surface
                border.width: 1
                border.color: root.st.caret_color

                Text {
                    id: label_text
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.spec.label || ""
                    color: root.st.text_accent
                    font.family: root.st.mono_font
                    font.pixelSize: root.st.font_size - 1
                    font.bold: true
                }

                TextInput {
                    id: input
                    anchors.left: label_text.right
                    anchors.leftMargin: label_text.text === "" ? 0 : 4
                    anchors.right: count_text.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    focus: true
                    clip: true
                    color: root.st.text_fg
                    selectionColor: root.st.selection_bg
                    selectedTextColor: root.st.selection_inverse ? root.st.selection_fg : root.st.text_fg
                    font.family: root.st.mono_font
                    font.pixelSize: root.st.font_size - 1
                    onTextChanged: {
                        if (root.applying) return;
                        root.cycle_base = null;
                        root.selected = -1;
                        root.menu_hidden = false;
                        root.history_index = -1;
                    }
                    // A static caret: the default one blinks for as long as the bar is open.
                    cursorDelegate: Rectangle {
                        width: 2
                        visible: input.activeFocus
                        color: root.st.caret_color
                    }

                    // Runs before TextInput's own handling, so Tab, Ctrl+U and Ctrl+W never reach it.
                    Keys.onPressed: event => root.handle_input_key(event)
                }

                Text {
                    id: count_text
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.menu_shown ? (root.selected >= 0 ? root.selected + 1 + "/" : "") + root.items.length : ""
                    color: root.st.text_primary
                    font.family: root.st.font_family
                    font.pixelSize: root.st.font_size - 4
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.IBeamCursor
                }
            }
        }

        FocusScope {
            id: output_scope
            anchors.fill: parent
            visible: root.is_output
            focus: root.is_output

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                const k = event.key;
                const line = root.st.font_size + 4;
                if (k === Qt.Key_Return || k === Qt.Key_Enter) Popups.close();
                else if (k === Qt.Key_J || k === Qt.Key_Down) root.scroll_output(line);
                else if (k === Qt.Key_K || k === Qt.Key_Up) root.scroll_output(-line);
                else if (ctrl && k === Qt.Key_D || k === Qt.Key_PageDown) root.scroll_output(output_view.height / 2);
                else if (ctrl && k === Qt.Key_U || k === Qt.Key_PageUp) root.scroll_output(-output_view.height / 2);
                else return;
                event.accepted = true;
            }

            Text {
                id: output_label
                width: parent.width
                elide: Text.ElideRight
                text: (root.spec.label || "") + (root.spec.text || "")
                color: root.st.text_accent
                font.family: root.st.mono_font
                font.pixelSize: root.st.font_size - 2
                font.bold: true
            }

            Flickable {
                id: output_view
                y: output_label.height + 8
                width: parent.width
                height: root.output_height
                clip: true
                contentWidth: width
                contentHeight: output_text.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: output_text
                    width: output_view.width
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    text: root.output_text
                    color: root.st.text_fg
                    font.family: root.st.mono_font
                    font.pixelSize: root.st.font_size - 3
                }
            }
        }
    }
}
