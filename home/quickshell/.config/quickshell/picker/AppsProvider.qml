// home/quickshell/.config/quickshell/picker/AppsProvider.qml
import QtQuick
import Quickshell
import "../services"

PickerProvider {
    id: root

    name: "apps"
    title: "Apps"
    placeholder: "Search apps"
    columns: 4

    function refresh() {
        root.items = DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
            id: e.id,
            label: e.name,
            description: e.comment !== "" ? e.comment : e.genericName,
            icon: e.icon,
            keywords: [e.genericName].concat(Array.from(e.keywords), Array.from(e.categories)),
            entry: e
        }));
    }

    function activate(item) {
        const e = item.entry;
        if (!e) return;
        if (e.runInTerminal) {
            const context = { command: [Quickshell.env("HOME") + "/.config/hypr/scripts/term", "-e"].concat(Array.from(e.command)) };
            if (e.workingDirectory !== "") context.workingDirectory = e.workingDirectory;
            Quickshell.execDetached(context);
        } else {
            e.execute();
        }
    }

    // Desktop files installed or removed while the picker is open.
    Connections {
        target: DesktopEntries.applications
        enabled: Pickers.is_open && Pickers.provider_name === root.name
        function onValuesChanged() {
            root.refresh();
        }
    }
}
