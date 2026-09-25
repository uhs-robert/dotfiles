// home/quickshell/.config/quickshell/services/MetroidDraftIpc.qml
import Quickshell.Io
import "../theme"

// Temporary: flips the Metroid bar between draft shapes until one is picked.
IpcHandler {
    target: "metroid_draft"

    function bar(name: string): void {
        if (["current", "frame", "combat", "scan"].indexOf(name) < 0) {
            console.warn("metroid_draft: unknown bar " + name);
            return;
        }
        Style.metroid_bar_draft = name;
    }

    function list(): string {
        return "current: visor glass with rounded corners (default)\nframe: long tapering helmet-frame sweeps, double hairline, reticle marks under the clock\ncombat: notched bracket ends, energy-tank ticks along the bottom, crosshair under the clock\nscan: pod ends holding reticles, dotted scan line along the bottom\nactive: " + Style.metroid_bar;
    }
}
