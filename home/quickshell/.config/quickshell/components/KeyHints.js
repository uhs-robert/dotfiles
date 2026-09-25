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

// Keyboard keys (or "a/b" halves) to controller button ids, per the style's controller token.
const controller_maps = {
    ps1: { Enter: "cross", q: "circle", Esc: "circle", Backspace: "circle", Tab: "triangle", "[": "l1", "]": "r1", t: "square", "?": "select", gg: "l2", G: "r2", "j/k": "dpad_v", "h/l": "dpad_h", j: "dpad_down", k: "dpad_up", h: "dpad_left", l: "dpad_right" }
};

// A key as [{button}] and [{text}] parts, or null when the controller maps none of it.
function controller_parts(controller, key) {
    const map = controller_maps[controller];
    if (!map || key.indexOf("+") >= 0) return null;
    if (map[key] !== undefined) return [{ button: map[key] }];
    const pieces = key === "[ ]" ? ["[", "]"] : key.split("/");
    const parts = [];
    let hit = false;
    for (const p of pieces) {
        const b = map[p];
        if (b !== undefined) hit = true;
        if (b !== undefined && parts.length > 0 && parts[parts.length - 1].button === b) continue;
        if (parts.length > 0 && key !== "[ ]") parts.push({ text: "/" });
        parts.push(b !== undefined ? { button: b } : { text: with_glyphs(p) });
    }
    return hit ? parts : null;
}

const button_labels = { l1: "L1", r1: "R1", l2: "L2", r2: "R2", select: "SELECT" };

function button_label(id) {
    return button_labels[id] || "";
}

// A button's drawn width at height h; face buttons and the D-pad are square.
function button_width(id, h) {
    if (id === "select") return Math.round(h * 2.9);
    if (button_labels[id] !== undefined) return Math.round(h * 1.5);
    return h;
}

// The width of a parts row at height h, with measure(text) for the text parts.
function parts_width(parts, h, spacing, measure) {
    let w = 0;
    for (const p of parts) w += (p.button ? button_width(p.button, h) : measure(p.text)) + spacing;
    return Math.max(0, w - spacing);
}
