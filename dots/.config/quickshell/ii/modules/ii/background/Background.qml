pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.utils //FIXME. remove
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.common.functions as CF
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.ii.background.widgets
import qs.modules.ii.background.widgets.clock
import qs.modules.ii.background.widgets.weather
import qs.modules.ii.background.widgets.media
import "./widgets"

Variants {
    id: root
    model: Quickshell.screens
    
    PanelWindow {
        id: bgRoot

        required property var modelData
        property string currentWallpaperSource: Config.options.background.wallpaperPath
        property string previousWallpaperSource: Config.options.background.wallpaperPath

        property var shaderList: ["circle", "circlePit", "circleSelect", "magic", "Doom", "Peel", "transition", "slideLeft", "slideRight", "slideUp", "slideDown", "crt"]
        property var shaderShaders: ["circle", "circlePit", "circleSelect", "magic", "Doom", "Peel", "transition"]
        property string currentShader: "circle"
        property string wallpaperAnimation: Config.options.background.wallpaperAnimation ?? "random"

        property real transitionProgress: 1.0
        property real mouseX: 0
        property real mouseY: 0

        function stopAllAnimations() {
            transitionAnim.stop()
            crtAnim.stop()
            slideAnim.stop()
        }

        function resetVisuals() {
            wallpaperImage.scale = 1.0
            wallpaperImage.rotation = 0
            wallpaperImage.x = 0
            wallpaperImage.y = 0
            previousWallpaper.x = 0
            previousWallpaper.y = 0
            previousWallpaper.opacity = 1
            previousWallpaper.scale = 1
            wallpaperImage.opacity = 1
        }

        NumberAnimation {
            id: transitionAnim
            target: bgRoot
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: Config.options.background.wallpaperAnimationDuration
            easing.type: Easing.InOutCubic
            onFinished: {
                previousWallpaper.source = ""
                bgRoot.previousWallpaperSource = ""
                bgRoot.transitionProgress = 1.0
                resetVisuals()
            }
        }

        onWallpaperPathChanged: {
            bgRoot.updateZoomScale();
            stopAllAnimations();

            if (bgRoot.currentWallpaperSource === wallpaperPath) {
                resetVisuals();
                previousWallpaper.source = ""
                wallpaperImage.source = wallpaperPath
                bgRoot.transitionProgress = 1.0
                return
            }

            if (wallpaperSafetyTriggered) {
                resetVisuals();
                previousWallpaper.source = ""
                wallpaperImage.source = ""
                bgRoot.transitionProgress = 1.0
                return
            }
            if (bgRoot.wallpaperAnimation === "" || bgRoot.wallpaperAnimation === null) {
                resetVisuals();
                previousWallpaper.source = ""
                wallpaperImage.source = wallpaperPath
                bgRoot.currentWallpaperSource = wallpaperPath
                bgRoot.transitionProgress = 1.0
                return
            }

            previousWallpaper.source = bgRoot.currentWallpaperSource
            wallpaperImage.source = wallpaperPath
            bgRoot.currentWallpaperSource = wallpaperPath

            resetVisuals();

            if (bgRoot.wallpaperAnimation === "random") {
                bgRoot.currentShader = bgRoot.shaderList[Math.floor(Math.random() * bgRoot.shaderList.length)]
            } else {
                bgRoot.currentShader = bgRoot.wallpaperAnimation
            }

            if (bgRoot.currentShader.startsWith("slide")) {
                slideAnim.restart()
            } else if (bgRoot.currentShader === "crt") {
                crtAnim.restart()
            } else {
                bgRoot.transitionProgress = 0.0
                // In case it's already loaded or becomes ready instantly
                if (wallpaperImage.status === Image.Ready && bgRoot.shaderShaders.includes(bgRoot.currentShader)) {
                    transitionAnim.restart()
                }
            }
        }

        SequentialAnimation {
            id: crtAnim
            onFinished: {
                previousWallpaper.source = ""
                bgRoot.previousWallpaperSource = ""
                bgRoot.transitionProgress = 1.0
                resetVisuals()
                crtFlash.visible = false
            }
            // Immediate setup
            PropertyAction { target: wallpaperImage; property: "opacity"; value: 0 }
            PropertyAction { target: previousWallpaper; property: "opacity"; value: 1 }
            PropertyAction { target: previousWallpaper; property: "scale"; value: 1 }
            PropertyAction { target: bgRoot; property: "transitionProgress"; value: 0 }

            // Turn off
            ParallelAnimation {
                NumberAnimation { target: previousWallpaper; property: "scale"; to: 1.1; duration: 100 }
                NumberAnimation { target: previousWallpaper; property: "opacity"; to: 0.5; duration: 100 }
            }
            ParallelAnimation {
                NumberAnimation { target: previousWallpaper; property: "scale"; to: 0.01; duration: 300; easing.type: Easing.InBack }
                NumberAnimation { target: previousWallpaper; property: "opacity"; to: 0; duration: 300 }
            }
            // Flash
            PropertyAction { target: crtFlash; property: "visible"; value: true }
            PropertyAction { target: crtFlash; property: "width"; value: 0 }
            NumberAnimation { target: crtFlash; property: "width"; from: 0; to: bgRoot.width; duration: 150; easing.type: Easing.OutExpo }
            NumberAnimation { target: crtFlash; property: "height"; from: 10; to: 2; duration: 100 }
            PropertyAction { target: crtFlash; property: "visible"; value: false }
            
            // Turn on
            PropertyAction { target: wallpaperImage; property: "scale"; value: 0 }
            ParallelAnimation {
                NumberAnimation { target: wallpaperImage; property: "opacity"; to: 1; duration: 400; easing.type: Easing.OutBack }
                NumberAnimation { target: wallpaperImage; property: "scale"; to: 1; duration: 400; easing.type: Easing.OutBack }
                NumberAnimation { target: bgRoot; property: "transitionProgress"; to: 1.0; duration: 400 }
            }
        }

        ParallelAnimation {
            id: slideAnim
            onFinished: {
                previousWallpaper.source = ""
                bgRoot.previousWallpaperSource = ""
                bgRoot.transitionProgress = 1.0
                resetVisuals()
            }
            PropertyAction { target: bgRoot; property: "transitionProgress"; value: 0 }
            NumberAnimation {
                target: bgRoot
                property: "transitionProgress"
                from: 0.0
                to: 1.0
                duration: Config.options.background.wallpaperAnimationDuration
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: wallpaperImage
                property: "x"
                from: (bgRoot.currentShader === "slideLeft") ? bgRoot.width : (bgRoot.currentShader === "slideRight") ? -bgRoot.width : 0
                to: 0
                duration: Config.options.background.wallpaperAnimationDuration
                easing.type: Easing.OutExpo
            }
            NumberAnimation {
                target: previousWallpaper
                property: "x"
                from: 0
                to: (bgRoot.currentShader === "slideLeft") ? -bgRoot.width : (bgRoot.currentShader === "slideRight") ? bgRoot.width : 0
                duration: Config.options.background.wallpaperAnimationDuration
                easing.type: Easing.OutExpo
            }
            NumberAnimation {
                target: wallpaperImage
                property: "y"
                from: (bgRoot.currentShader === "slideUp") ? bgRoot.height : (bgRoot.currentShader === "slideDown") ? -bgRoot.height : 0
                to: 0
                duration: Config.options.background.wallpaperAnimationDuration
                easing.type: Easing.OutExpo
            }
            NumberAnimation {
                target: previousWallpaper
                property: "y"
                from: 0
                to: (bgRoot.currentShader === "slideUp") ? -bgRoot.height : (bgRoot.currentShader === "slideDown") ? bgRoot.height : 0
                duration: Config.options.background.wallpaperAnimationDuration
                easing.type: Easing.OutExpo
            }
        }

        // Hide when fullscreen
        property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
        property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
        visible: GlobalStates.screenLocked || (!(activeWorkspaceWithFullscreen != undefined)) || !Config?.options.background.hideWhenFullscreen

        // Workspaces
        property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        property list<var> relevantWindows: HyprlandData.windowList.filter(win => win.monitor == monitor?.id && win.workspace.id >= 0).sort((a, b) => a.workspace.id - b.workspace.id)
        property int firstWorkspaceId: relevantWindows[0]?.workspace.id || 1
        property int lastWorkspaceId: relevantWindows[relevantWindows.length - 1]?.workspace.id || 10

        // Wallpaper
        property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
        property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
        property bool wallpaperSafetyTriggered: {
            const enabled = Config.options.workSafety.enable.wallpaper;
            const sensitiveWallpaper = (CF.StringUtils.stringListContainsSubstring(wallpaperPath.toLowerCase(), Config.options.workSafety.triggerCondition.fileKeywords));
            const sensitiveNetwork = (CF.StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
            return enabled && sensitiveWallpaper && sensitiveNetwork;
        }
        property real wallpaperToScreenRatio: Math.min(wallpaperWidth / screen.width, wallpaperHeight / screen.height)
        property real preferredWallpaperScale: Config.options.background.parallax.workspaceZoom
        property real effectiveWallpaperScale: 1 // Some reasonable init value, to be updated
        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated
        property real movableXSpace: ((wallpaperWidth / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.width) / 2
        property real movableYSpace: ((wallpaperHeight / wallpaperToScreenRatio * effectiveWallpaperScale) - screen.height) / 2

        readonly property bool verticalParallax: (Config.options.background.parallax.autoVertical && wallpaperHeight > wallpaperWidth) || Config.options.background.parallax.vertical
        // Colors
        property bool shouldBlur: (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        property color dominantColor: Appearance.colors.colPrimary // Default, to be changed
        property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
        property color colText: {
            if (wallpaperSafetyTriggered)
                return CF.ColorUtils.mix(Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, 0.75);
            return (GlobalStates.screenLocked && shouldBlur) ? Appearance.colors.colOnLayer0 : CF.ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12));
        }
        Behavior on colText {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        readonly property bool isScrollingLayout: Persistent.states.hyprland.layout === "scrolling"

        property var zoomLevels: {  // has to be reverted compared to background
            "in": { default: 1.04, zoomed: 1 },
            "out": { default: 1, zoomed: 1.04 }
        }

        property real defaultRatio: zoomInStyle ? zoomLevels.in.default : zoomLevels.out.default
        property real zoomedRatio: zoomInStyle ? zoomLevels.in.zoomed : zoomLevels.out.zoomed

        readonly property bool zoomInStyle: Config.options.overview.scrollingStyle.zoomStyle === "in"
        readonly property bool showOpeningAnimation: Config.options.overview.showOpeningAnimation

        property bool overviewOpen: GlobalStates.overviewOpen

        property real scaleAnimated: GlobalStates.overviewOpen && showOpeningAnimation ? zoomedRatio : defaultRatio
        Behavior on scaleAnimated {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        // Layer props
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: (GlobalStates.screenLocked && !scaleAnim.running) ? WlrLayer.Top : WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: {
            if (!bgRoot.wallpaperSafetyTriggered || bgRoot.wallpaperIsVideo)
                return "transparent";
            return CF.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.75);
        }
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        // Wallpaper zoom scale
        function updateZoomScale() {
            getWallpaperSizeProc.path = bgRoot.wallpaperPath;
            getWallpaperSizeProc.running = true;
        }
        Process {
            id: getWallpaperSizeProc
            property string path: bgRoot.wallpaperPath
            command: ["magick", "identify", "-format", "%w %h", CF.FileUtils.trimFileProtocol(path) + "[0]"]
            stdout: StdioCollector {
                id: wallpaperSizeOutputCollector
                onStreamFinished: {
                    const output = wallpaperSizeOutputCollector.text;
                    const [width, height] = output.split(" ").map(Number);
                    const [screenWidth, screenHeight] = [bgRoot.screen.width, bgRoot.screen.height];
                    bgRoot.wallpaperWidth = width;
                    bgRoot.wallpaperHeight = height;

                    if (width <= screenWidth || height <= screenHeight) {
                        // Undersized/perfectly sized wallpapers
                        bgRoot.effectiveWallpaperScale = Math.max(screenWidth / width, screenHeight / height);
                    } else {
                        // Oversized = can be zoomed for parallax, yay
                        bgRoot.effectiveWallpaperScale = Math.min(bgRoot.preferredWallpaperScale, width / screenWidth, height / screenHeight);
                    }
                }
            }
        }

        property bool mediaModeOpen: mediaModeLoader.active && MprisController.activePlayer
        onMediaModeOpenChanged: {
            if (!mediaModeOpen) {
                Wallpapers.apply(Config.options.background.wallpaperPath)
                LyricsService.shellColorChanged = false
            }
        }

        Component.onCompleted: {
            if (!Idle.trackedWindow) {
                Idle.trackedWindow = bgRoot;
            }
            if (!mediaModeOpen) {
                Wallpapers.apply(Config.options.background.wallpaperPath)
            }

            previousWallpaper.source = ""
            wallpaperImage.source = bgRoot.wallpaperSafetyTriggered ? "" : bgRoot.wallpaperPath
            bgRoot.currentWallpaperSource = bgRoot.wallpaperPath
            bgRoot.previousWallpaperSource = ""
            bgRoot.transitionProgress = 1.0
            if (bgRoot.wallpaperAnimation !== "") {
                bgRoot.currentShader = bgRoot.wallpaperAnimation === "random"
                    ? bgRoot.shaderList[Math.floor(Math.random() * bgRoot.shaderList.length)]
                    : bgRoot.wallpaperAnimation
            }
        }

        Item {
            id: wallpaperItem
            anchors.fill: parent
            clip: true
            scale: showOpeningAnimation && overviewOpen && bgRoot.isScrollingLayout ? zoomedRatio : defaultRatio
            opacity: mediaModeOpen ? 0 : 1
            
            Behavior on opacity {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }

            Behavior on scale {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }

            // Wallpaper
            Item {
                id: wallpaper
                visible: opacity > 0 && !blurLoader.active && !bgRoot.wallpaperIsVideo
                opacity: (wallpaperImage.status === Image.Ready && !bgRoot.wallpaperIsVideo) ? 1 : 0
                // Range = groups that workspaces span on
                property int chunkSize: Config?.options.bar.workspaces.shown ?? 10
                property int lower: Math.floor(bgRoot.firstWorkspaceId / chunkSize) * chunkSize
                property int upper: Math.ceil(bgRoot.lastWorkspaceId / chunkSize) * chunkSize
                property int range: upper - lower
                property real valueX: {
                    let result = 0.5;
                    if (Config.options.background.parallax.enableWorkspace && !bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);

                    }
                    return result;
                }
                property real sidebarOffsetX: {
                    if (!Config.options.background.parallax.enableSidebar) return 0;
                    return (0.15 * GlobalStates.effectiveRightOpen - 0.15 * GlobalStates.effectiveLeftOpen);

                }
                property real valueY: {
                    let result = 0.5;
                    if (Config.options.background.parallax.enableWorkspace && bgRoot.verticalParallax) {
                        result = ((bgRoot.monitor.activeWorkspace?.id - lower) / range);
                    }
                    return result;
                }
                property real effectiveValueX: Math.max(0, Math.min(1, valueX)) + sidebarOffsetX
                property real effectiveValueY: Math.max(0, Math.min(1, valueY))
                x: -(bgRoot.movableXSpace) - (effectiveValueX - 0.5) * 2 * bgRoot.movableXSpace
                y: -(bgRoot.movableYSpace) - (effectiveValueY - 0.5) * 2 * bgRoot.movableYSpace

                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.OutCubic
                    }
                }
                width: bgRoot.wallpaperWidth / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale
                height: bgRoot.wallpaperHeight / bgRoot.wallpaperToScreenRatio * bgRoot.effectiveWallpaperScale

                AnimatedImage {
                    id: previousWallpaper
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    smooth: true
                    asynchronous: true
                    playing: false
                    layer.enabled: true
                    visible: false // Managed by ShaderEffectSource or slide logic
                }

                AnimatedImage {
                    id: wallpaperImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    cache: true
                    smooth: true
                    asynchronous: true
                    playing: bgRoot.transitionProgress === 1.0
                    layer.enabled: true
                    visible: false // Managed by ShaderEffectSource or slide logic
                    onStatusChanged: {
                        if (status === AnimatedImage.Ready && bgRoot.transitionProgress === 0.0 && bgRoot.shaderShaders.includes(bgRoot.currentShader)) {
                            transitionAnim.restart()
                        }
                    }
                }

                ShaderEffectSource {
                    id: fromSource
                    sourceItem: previousWallpaper
                    hideSource: false
                    live: true
                    visible: false
                }

                ShaderEffectSource {
                    id: toSource
                    sourceItem: wallpaperImage
                    hideSource: false
                    live: true
                    visible: false
                }

                ShaderEffect {
                    id: transitionEffect
                    anchors.fill: parent
                    visible: !blurLoader.active && bgRoot.shaderShaders.includes(bgRoot.currentShader) && bgRoot.transitionProgress < 1.0
                    property var fromImage: fromSource
                    property var toImage: toSource
                    property real progress: bgRoot.transitionProgress
                    property real aspectX: width / height
                    property real aspectY: 1.0
                    property vector2d aspectRatio: Qt.vector2d(aspectX, aspectY)
                    property vector2d origin: Qt.vector2d(0.5, 0.5)
                    fragmentShader: (bgRoot.shaderShaders.includes(bgRoot.currentShader))
                        ? Qt.resolvedUrl(`shaders/${bgRoot.currentShader}.frag.qsb`)
                        : ""
                }

                // Show the actual image when not animating or during Slide/CRT
                Loader {
                    anchors.fill: parent
                    active: bgRoot.transitionProgress === 1.0 || bgRoot.currentShader.startsWith("slide") || bgRoot.currentShader === "crt"
                    sourceComponent: Item {
                        anchors.fill: parent
                        // Only show previous wallpaper during CRT turn off phase or Slide
                        Item {
                            anchors.fill: parent
                            visible: (bgRoot.currentShader === "crt" || bgRoot.currentShader.startsWith("slide")) && bgRoot.transitionProgress < 1.0
                            opacity: previousWallpaper.opacity
                            scale: previousWallpaper.scale
                            x: previousWallpaper.x
                            y: previousWallpaper.y
                            AnimatedImage {
                                anchors.fill: parent
                                source: previousWallpaper.source
                                fillMode: Image.PreserveAspectCrop
                                playing: false
                            }
                        }
                        // Actual wallpaper
                        AnimatedImage {
                            anchors.fill: parent
                            source: wallpaperImage.source
                            playing: true
                            opacity: wallpaperImage.opacity
                            scale: wallpaperImage.scale
                            x: wallpaperImage.x
                            y: wallpaperImage.y
                            fillMode: Image.PreserveAspectCrop
                        }
                    }
                }

                Rectangle {
                    id: crtFlash
                    color: "white"
                    anchors.centerIn: parent
                    visible: false
                    height: 2
                    width: 0
                }
            }

            Loader {
                id: blurLoader
                active: Config.options.lock.blur.enable && (GlobalStates.screenLocked || scaleAnim.running)
                anchors.fill: wallpaper
                scale: GlobalStates.screenLocked ? Config.options.lock.blur.extraZoom : 1
                Behavior on scale {
                    NumberAnimation {
                        id: scaleAnim
                        duration: 400
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                    }
                }
                sourceComponent: GaussianBlur {
                    source: wallpaper
                    radius: GlobalStates.screenLocked ? Config.options.lock.blur.radius : 0
                    samples: radius * 2 + 1

                    Rectangle {
                        opacity: GlobalStates.screenLocked ? 1 : 0
                        anchors.fill: parent
                        color: CF.ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
                    }
                }
            }

            FunEffects {
                id: funEffects
                mouseX: bgRoot.mouseX
                mouseY: bgRoot.mouseY
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: (mouse) => {
                    bgRoot.mouseX = mouse.x
                    bgRoot.mouseY = mouse.y
                }
                onPressed: (mouse) => {
                    funEffects.burst(mouse.x, mouse.y)
                }
            }

            WidgetCanvas {
                id: widgetCanvas
                scale: 1 - (defaultRatio - 1)
                Behavior on scale {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                anchors {
                    left: wallpaper.left
                    right: wallpaper.right
                    top: wallpaper.top
                    bottom: wallpaper.bottom
                    horizontalCenter: undefined
                    verticalCenter: undefined
                    readonly property real parallaxFactor: Config.options.background.parallax.widgetsFactor
                    leftMargin: {
                        const xOnWallpaper = bgRoot.movableXSpace;
                        const extraMove = (wallpaper.effectiveValueX * 2 * bgRoot.movableXSpace) * (parallaxFactor - 1);
                        return xOnWallpaper - extraMove;
                    }
                    topMargin: {
                        const yOnWallpaper = bgRoot.movableYSpace;
                        const extraMove = (wallpaper.effectiveValueY * 2 * bgRoot.movableYSpace) * (parallaxFactor - 1);
                        return yOnWallpaper - extraMove;
                    }
                    Behavior on leftMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                    Behavior on topMargin {
                        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                    }
                }
                width: wallpaper.width
                height: wallpaper.height
                states: State {
                    name: "centered"
                    when: GlobalStates.screenLocked || bgRoot.wallpaperSafetyTriggered
                    PropertyChanges {
                        target: widgetCanvas
                        width: parent.width
                        height: parent.height
                    }
                    AnchorChanges {
                        target: widgetCanvas
                        anchors {
                            left: undefined
                            right: undefined
                            top: undefined
                            bottom: undefined
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }

                transitions: Transition {
                    PropertyAnimation {
                        properties: "width,height"
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                    AnchorAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Appearance.animation.elementMove.type
                        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                    }
                }

                FadeLoader {
                    shown: Config.options?.background?.widgets?.weather?.enable ?? false
                    sourceComponent: WeatherWidget {                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                    }
                }

                FadeLoader {
                    shown: Config.options.background.widgets.clock.enable
                    sourceComponent: ClockWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                        wallpaperSafetyTriggered: bgRoot.wallpaperSafetyTriggered
                    }
                }

                Timer {
                    id: mediaTimer
                    interval: 200
                    onTriggered: mediaLoader.enableLoading = true
                }

                FadeLoader {
                    id: mediaLoader
                    property bool enableLoading: true
                    shown: Config.options.background.widgets.media.enable && enableLoading
                    sourceComponent: MediaWidget {
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width / bgRoot.effectiveWallpaperScale
                        scaledScreenHeight: bgRoot.screen.height / bgRoot.effectiveWallpaperScale
                        wallpaperScale: bgRoot.effectiveWallpaperScale
                    }
                    onLoaded: {
                        if (item && item.requestReset) {
                            item.requestReset.connect(() => { // hard reset
                                mediaLoader.enableLoading = false
                                mediaTimer.running = true
                            })
                        }
                    }
                }
            } // end of widgetCanvas
        } // end of wallpaperItem

        GlobalShortcut {
            name: "mediaModeToggle"
            description: "Toggles media mode on press"

            onPressed: {
                if (!monitor.focused && Config.options.background.mediaMode.togglePerMonitor) return
                mediaModeLoader.active = !mediaModeLoader.active
                LyricsService.mediaModeOpenCount += mediaModeLoader.active ? 1 : -1
            }
        }
        
        Loader {
            id: mediaModeLoader
            anchors.fill: parent
            active: false
            asynchronous: true
            sourceComponent: MediaMode {}
            opacity: status === Loader.Ready ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
