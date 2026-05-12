import qs.modules.common
import QtQuick

Canvas {
    id: root
    property real amplitudeMultiplier: 0.5
    property real frequency: 6
    property color color: Appearance?.colors.colPrimary ?? "#685496"
    property real lineWidth: 4
    property real fullLength: width

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        if (root.width <= 0 || root.fullLength <= 0) return;

        var amplitude = root.lineWidth * root.amplitudeMultiplier;
        var frequency = root.frequency;
        var phase = (Date.now() % 10000000) / 400.0;
        var centerY = height / 2;

        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.lineWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        
        var step = Math.max(0.5, root.width / 500); // Higher resolution for smoother curves
        for (var x = 0; x <= root.width; x += step) {
            var waveY = centerY + amplitude * Math.sin(frequency * 2 * Math.PI * x / root.fullLength + phase);
            if (x === 0)
                ctx.moveTo(x, waveY);
            else
                ctx.lineTo(x, waveY);
        }
        
        // Ensure we draw to the very end
        if (root.width % step !== 0) {
            var finalX = root.width;
            var finalY = centerY + amplitude * Math.sin(frequency * 2 * Math.PI * finalX / root.fullLength + phase);
            ctx.lineTo(finalX, finalY);
        }
        
        ctx.stroke();
    }
}
