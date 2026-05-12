import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import "../"

AbstractBackgroundWidget {
    id: root
    configEntryName: "visualizer"
    
    property Item anchorTarget: parent

    readonly property string placement: configEntry.placementStrategy
    readonly property bool isFree: placement === "free"
    
    // Snapping logic
    readonly property bool snappedTop: placement === "top"
    readonly property bool snappedBottom: placement === "bottom"
    readonly property bool snappedLeft: placement === "left"
    readonly property bool snappedRight: placement === "right"
    readonly property bool isSnapped: snappedTop || snappedBottom || snappedLeft || snappedRight

    readonly property bool isHorizontal: snappedTop || snappedBottom || isFree
    readonly property bool isVertical: snappedLeft || snappedRight
    
    readonly property real totalSpacing: (configEntry.bars - 1) * configEntry.barSpacing
    
    // Length/Width logic
    readonly property real customLength: configEntry.x
    readonly property real barWidth: (customLength - totalSpacing) / configEntry.bars

    // If snapped, we fill the parent to ensure we can draw at any screen edge.
    // If free, we use the custom dimensions for dragging.
    anchors.fill: isSnapped ? anchorTarget : undefined
    fillParent: isSnapped // Disable AbstractBackgroundWidget x/y logic

    width: isSnapped ? (isHorizontal ? customLength : configEntry.height) : (isHorizontal ? customLength : configEntry.height)
    height: isSnapped ? (isVertical ? customLength : configEntry.height) : (isVertical ? customLength : configEntry.height)
    
    rotation: isFree ? configEntry.rotation : 0

    opacity: configEntry.opacity
    visible: configEntry.enable && opacity > 0

    property list<real> visualizerPoints: []

    readonly property bool barOnSameEdge: {
        const barAtBottom = Config.options.bar.bottom
        const barVertical = Config.options.bar.vertical
        
        if (barVertical) {
            return (snappedLeft && !barAtBottom) || (snappedRight && barAtBottom)
        } else {
            return (snappedTop && !barAtBottom) || (snappedBottom && barAtBottom)
        }
    }
    
    readonly property real barSize: Config.options.bar.vertical ? Config.options.bar.sizes.width : Config.options.bar.sizes.height
    readonly property real barAvoidanceOffset: (configEntry.avoidBar && barOnSameEdge && !Config.options.bar.borderless) ? barSize : 0

    Process {
        id: cavaProc
        running: root.visible
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let rawPoints = data.split(";").map(p => {
                    let val = parseFloat(p.trim());
                    return isNaN(val) ? 0 : val / 1000.0;
                }).filter(p => !isNaN(p));
                
                if (rawPoints.length === 0) {
                    root.visualizerPoints = [];
                    return;
                }
                
                let targetCount = configEntry.bars;
                let resampled = [];
                for (let i = 0; i < targetCount; i++) {
                    let index = (i / targetCount) * rawPoints.length;
                    let low = Math.floor(index);
                    let high = Math.min(low + 1, rawPoints.length - 1);
                    let weight = index - low;
                    resampled.push(rawPoints[low] * (1 - weight) + rawPoints[high] * weight);
                }

                // Apply data smoothing
                let smooth = configEntry.dataSmoothing ?? 0.5;
                if (root.visualizerPoints.length === resampled.length) {
                    for (let j = 0; j < targetCount; j++) {
                        resampled[j] = root.visualizerPoints[j] * smooth + resampled[j] * (1 - smooth);
                    }
                }
                root.visualizerPoints = resampled;
            }
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: configEntry.mode === "bars" ? barsComponent : waveComponent
    }

    Component {
        id: barsComponent
        Item {
            anchors.fill: parent
            
            // Visualizer container for snapped modes to handle offset and centering
            Item {
                id: visContainer
                width: isHorizontal ? root.customLength : configEntry.height
                height: isVertical ? root.customLength : configEntry.height
                
                anchors {
                    horizontalCenter: (snappedTop || snappedBottom) ? parent.horizontalCenter : undefined
                    verticalCenter: (snappedLeft || snappedRight) ? parent.verticalCenter : undefined
                    top: snappedTop ? parent.top : undefined
                    bottom: snappedBottom ? parent.bottom : undefined
                    left: snappedLeft ? parent.left : undefined
                    right: snappedRight ? parent.right : undefined
                    
                    topMargin: snappedTop ? root.barAvoidanceOffset : 0
                    bottomMargin: snappedBottom ? root.barAvoidanceOffset : 0
                    leftMargin: snappedLeft ? root.barAvoidanceOffset : 0
                    rightMargin: snappedRight ? root.barAvoidanceOffset : 0
                }

                Repeater {
                    model: root.visualizerPoints
                    delegate: Rectangle {
                        readonly property real amplitude: Math.min(modelData * configEntry.maxBarHeight, 1.0)
                        width: isHorizontal ? root.barWidth : amplitude * parent.width
                        height: isHorizontal ? amplitude * parent.height : root.barWidth
                        
                        x: isHorizontal ? index * (width + configEntry.barSpacing) : (snappedRight ? parent.width - width : 0)
                        y: isHorizontal ? (snappedTop ? 0 : parent.height - height) : index * (height + configEntry.barSpacing)
                        
                        color: Appearance.colors.colPrimary
                        opacity: 0.6
                        radius: (isHorizontal ? width : height) * configEntry.barRounding
                    }
                }
            }
        }
    }

    Component {
        id: waveComponent
        Item {
            anchors.fill: parent
            Canvas {
                id: canvas
                width: isHorizontal ? root.customLength : configEntry.height
                height: isVertical ? root.customLength : configEntry.height
                
                anchors {
                    horizontalCenter: (snappedTop || snappedBottom) ? parent.horizontalCenter : undefined
                    verticalCenter: (snappedLeft || snappedRight) ? parent.verticalCenter : undefined
                    top: snappedTop ? parent.top : undefined
                    bottom: snappedBottom ? parent.bottom : undefined
                    left: snappedLeft ? parent.left : undefined
                    right: snappedRight ? parent.right : undefined
                    
                    topMargin: snappedTop ? root.barAvoidanceOffset : 0
                    bottomMargin: snappedBottom ? root.barAvoidanceOffset : 0
                    leftMargin: snappedLeft ? root.barAvoidanceOffset : 0
                    rightMargin: snappedRight ? root.barAvoidanceOffset : 0
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.clearRect(0, 0, width, height);
                    if (root.visualizerPoints.length < 2) return;

                    var points = root.visualizerPoints;
                    var len = points.length;
                    var roundness = configEntry.waveRoundness;
                    var maxAmp = configEntry.maxBarHeight;
                    
                    function getCoord(i) {
                        var v = Math.min(points[i] * maxAmp, 1.0);
                        if (isHorizontal) {
                            var x = (i / (len - 1)) * width;
                            var y = snappedTop ? (v * height) : height - (v * height);
                            return {x: x, y: y};
                        } else {
                            var y_vert = (i / (len - 1)) * height;
                            var x_vert = snappedLeft ? (v * width) : width - (v * width);
                            return {x: x_vert, y: y_vert};
                        }
                    }

                    ctx.beginPath();
                    if (isHorizontal) {
                        ctx.moveTo(0, snappedTop ? 0 : height);
                    } else {
                        ctx.moveTo(snappedLeft ? 0 : width, 0);
                    }

                    var start = getCoord(0);
                    ctx.lineTo(start.x, start.y);

                    for (var i = 0; i < len - 1; i++) {
                        var p0 = getCoord(i);
                        var p1 = getCoord(i + 1);
                        if (roundness > 0) {
                            var cp1x = isHorizontal ? p0.x + (p1.x - p0.x) * 0.5 * roundness : p0.x;
                            var cp1y = isHorizontal ? p0.y : p0.y + (p1.y - p0.y) * 0.5 * roundness;
                            var cp2x = isHorizontal ? p1.x - (p1.x - p0.x) * 0.5 * roundness : p1.x;
                            var cp2y = isHorizontal ? p1.y : p1.y - (p1.y - p0.y) * 0.5 * roundness;
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, p1.x, p1.y);
                        } else {
                            ctx.lineTo(p1.x, p1.y);
                        }
                    }

                    if (isHorizontal) {
                        ctx.lineTo(width, snappedTop ? 0 : height);
                    } else {
                        ctx.lineTo(snappedLeft ? 0 : width, height);
                    }
                    ctx.closePath();
                    ctx.fillStyle = ColorUtils.transparentize(Appearance.colors.colPrimary, configEntry.waveFillOpacity);
                    ctx.fill();

                    if (configEntry.waveBorderWidth > 0) {
                        ctx.beginPath();
                        var s = getCoord(0);
                        ctx.moveTo(s.x, s.y);
                        for (var j = 0; j < len - 1; j++) {
                            var p0s = getCoord(j);
                            var p1s = getCoord(j + 1);
                            if (roundness > 0) {
                                var scp1x = isHorizontal ? p0s.x + (p1s.x - p0s.x) * 0.5 * roundness : p0s.x;
                                var scp1y = isHorizontal ? p0s.y : p0s.y + (p1s.y - p0s.y) * 0.5 * roundness;
                                var scp2x = isHorizontal ? p1s.x - (p1s.x - p0s.x) * 0.5 * roundness : p1s.x;
                                var scp2y = isHorizontal ? p1s.y : p1s.y - (p1s.y - p0s.y) * 0.5 * roundness;
                                ctx.bezierCurveTo(scp1x, scp1y, scp2x, scp2y, p1s.x, p1s.y);
                            } else {
                                ctx.lineTo(p1s.x, p1s.y);
                            }
                        }
                        ctx.lineWidth = configEntry.waveBorderWidth;
                        ctx.strokeStyle = Appearance.colors.colPrimary;
                        ctx.stroke();
                    }
                }

                Connections {
                    target: root
                    function onVisualizerPointsChanged() { canvas.requestPaint(); }
                }
            }
        }
    }
}
