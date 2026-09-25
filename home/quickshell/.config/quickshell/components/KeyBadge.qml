// home/quickshell/.config/quickshell/components/KeyBadge.qml
import QtQuick
import "../theme"
import "KeyHints.js" as KeyHints

Rectangle {
    id: root

    readonly property var st: Style.for_item(root)

    property string key: ""
    // Set on a filled active tab so an outline badge takes the tab's text color; keycap badges keep theirs.
    property bool on_fill: false
    readonly property bool tinted: root.on_fill && root.st.key_bg.a === 0 && !root.orb
    // The style's controller button for this key; pair also shows the key after it.
    readonly property string button: KeyHints.button(root.key, root.st.controller)
    readonly property bool pad: root.button !== ""
    property bool pair: false

    implicitWidth: root.pad ? pad_loader.width + (root.pair ? key_text.implicitWidth + 4 : 0) : Math.max(implicitHeight, key_text.implicitWidth + 8)
    implicitHeight: Math.max(key_text.implicitHeight + 2, pad_loader.height)
    width: implicitWidth
    height: implicitHeight
    radius: root.st.key_round ? height / 2 : Style.radius(3)
    readonly property bool cut: root.st.key_cut > 0
    readonly property bool orb: root.st.materia.key !== undefined && !root.pad
    color: root.cut || root.orb || root.pad ? "transparent" : root.st.key_bg
    border.width: root.cut || root.orb || root.pad ? 0 : root.st.pixel_border.a > 0 ? 2 : 1
    border.color: root.tinted ? root.st.tab_active_fg : root.st.key_border

    CutBox {
        visible: root.cut && !root.pad
        anchors.fill: parent
        cut_tl: root.st.key_cut
        cut_br: root.st.key_cut
        fill: root.st.key_bg
        stroke: root.tinted ? root.st.tab_active_fg : root.st.key_border
    }

    MateriaOrb {
        visible: root.orb
        anchors.fill: parent
        color: root.orb ? root.st.materia.key : "transparent"
    }

    Loader {
        id: pad_loader
        anchors.verticalCenter: parent.verticalCenter
        source: root.pad ? root.st.controller + "/ControllerButton.qml" : ""
        onLoaded: item.button = Qt.binding(() => root.button)
    }

    Text {
        id: key_text
        visible: !root.pad || root.pair
        anchors.centerIn: root.pad ? undefined : parent
        anchors.verticalCenter: root.pad ? parent.verticalCenter : undefined
        x: root.pad ? pad_loader.width + 4 : 0
        text: root.key
        color: root.tinted ? root.st.tab_active_fg : root.st.key_fg
        font.family: root.st.mono_font
        font.pixelSize: root.st.font_size - 5
        font.bold: root.orb || root.st.mono_font === root.st.font_family
    }
}
