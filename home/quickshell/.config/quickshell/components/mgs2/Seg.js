// home/quickshell/.config/quickshell/components/mgs2/Seg.js
.pragma library

const face_set = /^[A-Z0-9\/\-_?:.# <>%+!,'()\[\]=*°]*$/;

// True when the segment face can draw every character of text.
function supported(text) {
    return face_set.test(String(text).toUpperCase());
}
