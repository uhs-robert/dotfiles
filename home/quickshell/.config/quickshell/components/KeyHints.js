// home/quickshell/.config/quickshell/components/KeyHints.js
.pragma library

const key_glyphs = { Enter: String.fromCodePoint(0xF0311), Esc: String.fromCodePoint(0xF12B7), Tab: String.fromCodePoint(0xF0312), space: String.fromCodePoint(0xF1050), Backspace: String.fromCodePoint(0xF030D) };

function with_glyphs(text) {
    return text.replace(/\b(Enter|Esc|Tab|space|Backspace)\b/g, k => key_glyphs[k]);
}

// Splits "key desc · key desc" into groups; "[ ]" is the one key that contains a space.
function parse(text) {
    return text === "" ? [] : text.split(" · ").map(g => {
        const key = g.startsWith("[ ]") ? "[ ]" : g.split(" ")[0];
        return { key: key, desc: g.slice(key.length).trim() };
    });
}

// Keyboard key -> controller button, per Style.controller; unmapped keys keep their badge.
const pad_maps = {
    snes: { "Enter": "a", "q": "b", "Esc": "b", "Backspace": "b", "Tab": "start", "[ ]": "lr", "t": "y", "?": "x", "j/k": "dpad_v", "h/l": "dpad_h" }
};

// A key's parts as { button, text }, e.g. "t/Enter" gives y then a; empty when no part maps.
function pad_parts(controller, key) {
    const map = pad_maps[controller];
    if (!map) return [];
    if (map[key]) return [{ button: map[key], text: key }];
    const parts = [];
    let hit = false;
    for (const k of key.split("/")) {
        const button = map[k] || "";
        if (button !== "" && parts.some(p => p.button === button)) continue;
        if (button !== "") hit = true;
        parts.push({ button: button, text: k });
    }
    return hit ? parts : [];
}
