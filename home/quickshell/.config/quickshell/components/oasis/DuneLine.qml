// home/quickshell/.config/quickshell/components/oasis/DuneLine.qml
import QtQuick

// A dune contour divider: two wavy lines, fading out to the right or at both ends. Painted once per size or color change.
Canvas {
    id: root

    property color color: "transparent"
    // "right" fades from the left end out; "both" fades in and out.
    property string fade: "right"

    implicitHeight: 9

    function css(c, a) {
        return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + (c.a * a).toFixed(3) + ")";
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (root.width <= 0 || root.color.a <= 0) return;
        const g = ctx.createLinearGradient(0, 0, root.width, 0);
        if (root.fade === "both") {
            g.addColorStop(0, root.css(root.color, 0));
            g.addColorStop(0.18, root.css(root.color, 1));
            g.addColorStop(0.82, root.css(root.color, 1));
            g.addColorStop(1, root.css(root.color, 0));
        } else {
            g.addColorStop(0, root.css(root.color, 1));
            g.addColorStop(0.7, root.css(root.color, 0.4));
            g.addColorStop(1, root.css(root.color, 0));
        }
        const k = root.height / 9;
        ctx.lineWidth = 1;
        ctx.strokeStyle = g;
        ctx.beginPath();
        for (let x = 0; x < root.width; x += 96) {
            ctx.moveTo(x, 3 * k);
            ctx.bezierCurveTo(x + 16, 0.8 * k, x + 32, 0.8 * k, x + 48, 3 * k);
            ctx.bezierCurveTo(x + 64, 5.2 * k, x + 80, 5.2 * k, x + 96, 3 * k);
        }
        ctx.stroke();
        ctx.globalAlpha = 0.45;
        ctx.beginPath();
        for (let x = 0; x < root.width; x += 96) {
            ctx.moveTo(x, 7 * k);
            ctx.bezierCurveTo(x + 20, 5.4 * k, x + 36, 5.4 * k, x + 52, 7.2 * k);
            ctx.bezierCurveTo(x + 68, 9 * k, x + 82, 8.2 * k, x + 96, 7 * k);
        }
        ctx.stroke();
    }

    onWidthChanged: root.requestPaint()
    onHeightChanged: root.requestPaint()
    onColorChanged: root.requestPaint()
    onFadeChanged: root.requestPaint()
}
