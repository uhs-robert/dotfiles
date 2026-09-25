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

const glyph_names = Object.keys(key_glyphs).reduce((m, k) => {
    m[key_glyphs[k]] = k;
    return m;
}, {});

// Keyboard key -> controller button per console (Style.controller); a combined key maps whole or by its "/" halves.
const controller_maps = {
    nes: { Enter: "a", q: "b", Esc: "b", Backspace: "b", Tab: "start", "[ ]": "select", "j/k": "dpad_v", "h/l": "dpad_h", "Up/Down": "dpad_v" },
    snes: { Enter: "a", q: "b", Esc: "b", Backspace: "b", Tab: "start", "[ ]": "lr", t: "y", "?": "x", "j/k": "dpad_v", "h/l": "dpad_h" },
    ps1: { Enter: "cross", q: "circle", Esc: "circle", Backspace: "circle", Tab: "triangle", "[": "l1", "]": "r1", t: "square", "?": "select", gg: "l2", G: "r2", "j/k": "dpad_v", "h/l": "dpad_h", j: "dpad_down", k: "dpad_up", h: "dpad_left", l: "dpad_right" },
    ps2: { Enter: "cross", q: "circle", Esc: "circle", Backspace: "circle", Tab: "triangle", "[": "l1", "]": "r1", t: "square", "?": "select", gg: "l2", G: "r2", "/": "r3", j: "dpad_v", k: "dpad_v", h: "dpad_h", l: "dpad_h" }
};

// A key (glyphs allowed) as [{ button } | { text }] parts, "/" text between halves; [] when nothing maps.
function controller_parts(controller, key) {
    const map = controller_maps[controller];
    if (!map || !key || key.indexOf("+") >= 0) return [];
    let k = key;
    for (const g in glyph_names) k = k.split(g).join(glyph_names[g]);
    if (map[k] !== undefined) return [{ button: map[k] }];
    const pieces = k === "/" ? ["/"] : k === "[ ]" ? ["[", "]"] : k.split("/");
    const parts = [];
    let hit = false;
    for (const p of pieces) {
        const b = map[p];
        if (b !== undefined) hit = true;
        if (b !== undefined && parts.length > 0 && parts[parts.length - 1].button === b) continue;
        if (parts.length > 0 && k !== "[ ]") parts.push({ text: "/" });
        parts.push(b !== undefined ? { button: b } : { text: p });
    }
    return hit ? parts : [];
}
