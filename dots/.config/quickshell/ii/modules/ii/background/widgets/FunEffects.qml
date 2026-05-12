import QtQuick
import QtQuick.Particles
import qs.modules.common

Item {
    id: root
    anchors.fill: parent

    property real mouseX: 0
    property real mouseY: 0

    property bool snowEnabled: Config.options.background.effects.snow
    property bool rainEnabled: Config.options.background.effects.rain

    function burst(x, y) {
        clickEmitter.x = x
        clickEmitter.y = y
        clickEmitter.burst(20)
    }

    ParticleSystem {
        id: sys
        running: root.snowEnabled || root.rainEnabled || clickEmitter.enabled
    }

    Emitter {
        id: clickEmitter
        system: sys
        enabled: true
        emitRate: 0
        lifeSpan: 1000
        size: 10
        sizeVariation: 5
        velocity: AngleDirection {
            angle: 0
            angleVariation: 360
            magnitude: 100
            magnitudeVariation: 50
        }
    }

    ImageParticle {
        system: sys
        source: "qrc:///particleresources/fuzzydot.png"
        color: Appearance.colors.colPrimary
        opacity: 0.8
    }

    // Snow Effect
    Emitter {
        id: snowEmitter
        system: sys
        group: "snow"
        enabled: root.snowEnabled
        emitRate: 50
        lifeSpan: 8000
        maximumEmitted: 1000
        size: 8
        sizeVariation: 8
        velocity: PointDirection { y: 40; yVariation: 20; xVariation: 10 }
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        width: parent.width
        height: 10
    }

    // Rain Effect
    Emitter {
        id: rainEmitter
        system: sys
        group: "rain"
        enabled: root.rainEnabled
        emitRate: 200
        lifeSpan: 2000
        maximumEmitted: 2000
        size: 2
        velocity: PointDirection { y: 600; yVariation: 100 }
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        width: parent.width
        height: 10
    }

    ImageParticle {
        system: sys
        visible: root.snowEnabled
        source: "qrc:///particleresources/fuzzydot.png"
        color: "#FFFFFF"
        opacity: 0.8
        groups: ["snow"]
    }

    ImageParticle {
        system: sys
        visible: root.rainEnabled
        source: "qrc:///particleresources/fuzzydot.png"
        color: "#88AAFF"
        opacity: 0.4
        groups: ["rain"]
    }
}
