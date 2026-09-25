// home/quickshell/.config/quickshell/services/OasisDraftIpc.qml
import Quickshell
import Quickshell.Io
import "OasisDraft.js" as Draft
import "../theme"

// Temporary: switches the oasis frame and foot drafts live until one pair is picked.
Scope {
    id: root

    property var osd: null

    IpcHandler {
        target: "oasis_draft"

        function frame(name: string): string {
            if (name !== "" && Draft.frames.indexOf(name) < 0) return "unknown frame " + name;
            Style.draft_frame = name;
            return Style.oasis_frame;
        }

        function foot(name: string): string {
            if (name !== "" && Draft.feet.indexOf(name) < 0) return "unknown foot " + name;
            Style.draft_foot = name;
            return Style.oasis_foot;
        }

        function osd_preview(): void {
            if (root.osd) root.osd.show("volume", 0.62, false);
        }

        function list(): string {
            return "frames: " + Draft.frames.join(" ") + "\nfeet: " + Draft.feet.join(" ") + "\ncurrent: " + Style.oasis_frame + " " + Style.oasis_foot;
        }
    }
}
