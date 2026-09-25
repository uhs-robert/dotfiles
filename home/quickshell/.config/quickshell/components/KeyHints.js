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

const glyph_keys = Object.keys(key_glyphs).reduce((m, k) => {
    m[key_glyphs[k]] = k;
    return m;
}, {});

// Keyboard key -> controller button id, per Style.controller; unmapped keys keep their badge.
const controller_buttons = {
    nes: { "Enter": "a", "q": "b", "Esc": "b", "q/Esc": "b", "Esc/q": "b", "Esc/Backspace": "b", "Backspace": "b", "Tab": "start", "[ ]": "select", "j/k": "dpad_v", "Up/Down": "dpad_v", "h/l": "dpad_h" }
};

function button(key, controller) {
    const map = controller_buttons[controller];
    if (!map) return "";
    let raw = key;
    for (const g in glyph_keys) raw = raw.split(g).join(glyph_keys[g]);
    return map[raw] || "";
}
