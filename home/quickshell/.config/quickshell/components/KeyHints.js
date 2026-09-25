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

// Keyboard key -> controller button per console; j/k and h/l become the D-pad.
const controller_maps = {
    ps2: { Enter: "cross", q: "circle", Esc: "circle", Backspace: "circle", Tab: "triangle", t: "square", "?": "select", gg: "l2", G: "r2", "/": "r3", j: "dpad_v", k: "dpad_v", h: "dpad_h", l: "dpad_h", "[": "l1", "]": "r1" }
};

// A hint key as [{ button } | { text }] parts for `controller`; [] when none of it maps.
function controller_parts(key, controller) {
    const map = controller_maps[controller];
    if (!map || key === "" || key.indexOf("+") >= 0) return [];
    let k = key;
    for (const name in key_glyphs) k = k.split(key_glyphs[name]).join(name);
    const names = k === "/" ? ["/"] : k === "[ ]" ? ["[", "]"] : k.split("/");
    const parts = [];
    for (const n of names) {
        const b = map[n];
        if (b && parts.length > 0 && parts[parts.length - 1].button === b) continue;
        parts.push(b ? { button: b } : { text: n });
    }
    return parts.some(p => p.button) ? parts : [];
}
