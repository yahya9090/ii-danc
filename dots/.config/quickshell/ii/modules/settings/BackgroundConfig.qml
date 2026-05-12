import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: page
    readonly property int index: 3
    property bool register: parent.register ?? false
    forceWidth: true
    
    property bool allowHeavyLoads: false
    Component.onCompleted: Qt.callLater(() => page.allowHeavyLoads = true)

    ContentSection {
        icon: "wallpaper"
        title: Translation.tr("Wallpaper selector")

        ContentSubsection {
            title: Translation.tr("Style")
            ConfigSelectionArray {
                currentValue: Config.options.wallpaperSelector.style
                onSelected: newValue => {
                    Config.options.wallpaperSelector.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "grid_view",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Modern"),
                        icon: "style",
                        value: "modern"
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "sync_alt"
        title: Translation.tr("Parallax")

        ConfigSwitch {
            buttonIcon: "unfold_more_double"
            text: Translation.tr("Vertical")
            checked: Config.options.background.parallax.vertical
            onCheckedChanged: {
                HyprlandSettings.changeAnimation("workspaces", checked ? "slidevert" : "slide");
                Config.options.background.parallax.vertical = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "counter_1"
                text: Translation.tr("Depends on workspace")
                checked: Config.options.background.parallax.enableWorkspace
                onCheckedChanged: {
                    Config.options.background.parallax.enableWorkspace = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "side_navigation"
                text: Translation.tr("Depends on sidebars")
                checked: Config.options.background.parallax.enableSidebar
                onCheckedChanged: {
                    Config.options.background.parallax.enableSidebar = checked;
                }
            }
        }
        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Preferred wallpaper zoom (%)")
            value: Config.options.background.parallax.workspaceZoom * 100
            from: 10
            to: 200
            stepSize: 1
            onValueChanged: {
                Config.options.background.parallax.workspaceZoom = value / 100;
            }
        }
        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Animate wallpaper changes")
            checked: Config.options.background.animateWallpaperChanges
            onCheckedChanged: {
                Config.options.background.animateWallpaperChanges = checked;
            }
        }

        ConfigSlider {
            text: Translation.tr("Transition duration (ms)")
            textWidth: 200
            value: Config.options.background.wallpaperAnimationDuration
            from: 100
            to: 5000
            stepSize: 100
            buttonIcon: "schedule"
            usePercentTooltip: false
            onValueChanged: {
                Config.options.background.wallpaperAnimationDuration = value;
            }
        }

        ContentSubsection {
            title: Translation.tr("Transition style")
            Layout.fillWidth: true

            ConfigSelectionArray {
                currentValue: Config.options.background.wallpaperAnimation
                onSelected: newValue => {
                    Config.options.background.wallpaperAnimation = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("None"),
                        icon: "block",
                        value: ""
                    },
                    {
                        displayName: Translation.tr("Circle"),
                        icon: "circle",
                        value: "circle"
                    },
                    {
                        displayName: Translation.tr("Circle Pit"),
                        icon: "blur_circular",
                        value: "circlePit"
                    },
                    {
                        displayName: Translation.tr("Select"),
                        icon: "lasso_select",
                        value: "circleSelect"
                    },
                    {
                        displayName: Translation.tr("Magic"),
                        icon: "auto_awesome",
                        value: "magic"
                    },
                    {
                        displayName: Translation.tr("Doom"),
                        icon: "whatshot",
                        value: "Doom"
                    },
                    {
                        displayName: Translation.tr("Peel"),
                        icon: "layers",
                        value: "Peel"
                    },
                    {
                        displayName: Translation.tr("Fade"),
                        icon: "gradient",
                        value: "transition"
                    },
                    {
                        displayName: Translation.tr("Slide Left"),
                        icon: "arrow_back",
                        value: "slideLeft"
                    },
                    {
                        displayName: Translation.tr("Slide Right"),
                        icon: "arrow_forward",
                        value: "slideRight"
                    },
                    {
                        displayName: Translation.tr("Slide Up"),
                        icon: "arrow_upward",
                        value: "slideUp"
                    },
                    {
                        displayName: Translation.tr("Slide Down"),
                        icon: "arrow_downward",
                        value: "slideDown"
                    },
                    {
                        displayName: Translation.tr("CRT TV"),
                        icon: "tv",
                        value: "crt"
                    },
                    {
                        displayName: Translation.tr("Random"),
                        icon: "shuffle",
                        value: "random"
                    },
                ]
            }
        }
    }

    ContentSection {
        icon: "auto_awesome"
        title: Translation.tr("Fun Effects")
        tooltip: Translation.tr("Add some life to your desktop background with particles")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "ac_unit"
                text: Translation.tr("Snow")
                checked: Config.options.background.effects.snow
                onCheckedChanged: {
                    Config.options.background.effects.snow = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "umbrella"
                text: Translation.tr("Rain")
                checked: Config.options.background.effects.rain
                onCheckedChanged: {
                    Config.options.background.effects.rain = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "music_note"
        title: Translation.tr("Media mode")
        tooltip: Translation.tr("Toggle the mode with a keybind that executes 'quickshell:mediaModeToggle'\nExample: bindd = Super, Z, Toggle media mode, global, quickshell:mediaModeToggle")

        ConfigRow {

            ConfigSwitch {
                Layout.fillWidth: true
                buttonIcon: "monitor"
                text: Translation.tr("Toggle per monitor")
                checked: Config.options.background.mediaMode.togglePerMonitor
                onCheckedChanged: {
                    Config.options.background.mediaMode.togglePerMonitor = checked;
                }
            }

            RippleButtonWithShape {
                Layout.fillWidth: false

                shapeString: Config.options.background.mediaMode.backgroundShape
                implicitWidth: 60
                extraIcon: "edit"

                onClicked: {
                    mediaModeBackgroundShapeLoader.active = !mediaModeBackgroundShapeLoader.active;
                }
                StyledToolTip {
                    text: Translation.tr("Edit the material shape")
                }
            }
        }
        

        Loader { 
            id: mediaModeBackgroundShapeLoader
            active: false
            visible: active
            Layout.fillWidth: true
            sourceComponent: ContentSubsection {
                title: Translation.tr("Background shape")
                
                ConfigSelectionArray {
                    currentValue: Config.options.background.mediaMode.backgroundShape
                    onSelected: newValue => {
                        Config.options.background.mediaMode.backgroundShape = newValue;
                    }
                    options: ([ 
                        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill", "Triangle",
                        "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny", "Cookie4Sided", "Cookie6Sided", 
                        "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", 
                        "SoftBurst", "Flower", "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart" 
                    ]).map(icon => { 
                        return { 
                            displayName: "", 
                            shape: icon, 
                            value: icon 
                        } 
                    })
                }
            }
        }

        ConfigRow {
            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "animation"
                text: Translation.tr("Enable background animation")
                checked: Config.options.background.mediaMode.backgroundAnimation.enable
                onCheckedChanged: {
                    Config.options.background.mediaMode.backgroundAnimation.enable = checked;
                }
            }

            ConfigSpinBox {
                enabled: Config.options.background.mediaMode.backgroundAnimation.enable
                Layout.fillWidth: true
                icon: "speed"
                text: Translation.tr("Speed scale")
                value: Config.options.background.mediaMode.backgroundAnimation.speedScale
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.background.mediaMode.backgroundAnimation.speedScale = value;
                }

                MouseArea {
                    z: -1
                    id: spinBoxMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                StyledToolTip {
                    extraVisibleCondition: spinBoxMouseArea.containsMouse
                    text: Translation.tr("1: very slow | 10: default | 20: 2x speed...")
                }
            }
        }
        
        ConfigSwitch {
            buttonIcon: "format_color_fill"
            text: Translation.tr("Change shell color to match album art")
            checked: Config.options.background.mediaMode.changeShellColor
            onCheckedChanged: {
                Config.options.background.mediaMode.changeShellColor = checked;
            }
        }

        ConfigSpinBox {
            Layout.fillWidth: true
            icon: "opacity"
            text: Translation.tr("Background album art opacity (%)")
            value: Config.options.background.mediaMode.backgroundOpacity
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.background.mediaMode.backgroundOpacity = value;
            }
        }


        ContentSubsection {
            title: Translation.tr("Text highlight style")
            ConfigSelectionArray {
                currentValue: Config.options.background.mediaMode.syllable.textHighlightStyle
                onSelected: newValue => {
                    Config.options.background.mediaMode.syllable.textHighlightStyle = newValue;
                }
                options: [
                    {   
                        displayName: Translation.tr("Vertical"),
                        icon: "vertical_distribute",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Horizontal"),
                        icon: "horizontal_distribute",
                        value: 1
                    }
                ]
            }
        }
        
    }

    ContentSection {
        id: settingsClock
        icon: "clock_loader_40"
        title: Translation.tr("Widget: Clock")

        function stylePresent(styleName) {
            if (!Config.options.background.widgets.clock.showOnlyWhenLocked && Config.options.background.widgets.clock.style === styleName) {
                return true;
            }
            if (Config.options.background.widgets.clock.styleLocked === styleName) {
                return true;
            }
            return false;
        }

        readonly property bool digitalPresent: stylePresent("digital")
        readonly property bool cookiePresent: stylePresent("cookie")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.clock.enable
                onCheckedChanged: {
                    Config.options.background.widgets.clock.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.clock.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.clock.placementStrategy = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                ]
            }
            RippleButtonWithIcon {
                Layout.alignment: Qt.AlignRight
                materialIcon: "restart_alt"
                mainText: Translation.tr("Reset Position")
                onClicked: {
                    Config.options.background.widgets.clock.placementStrategy = "leastBusy";
                    Config.options.background.widgets.clock.x = 0;
                    Config.options.background.widgets.clock.y = 0;
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "lock_clock"
            text: Translation.tr("Show only when locked")
            checked: Config.options.background.widgets.clock.showOnlyWhenLocked
            onCheckedChanged: {
                Config.options.background.widgets.clock.showOnlyWhenLocked = checked;
            }
        }

        ConfigRow {
            ContentSubsection {
                visible: !Config.options.background.widgets.clock.showOnlyWhenLocked
                title: Translation.tr("Clock style")
                Layout.fillWidth: true
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.style
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.style = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Clock style (locked)")
                Layout.fillWidth: false
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.styleLocked
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.styleLocked = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Digital"),
                            icon: "timer_10",
                            value: "digital"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.digitalPresent
            title: Translation.tr("Digital clock settings")
            tooltip: Translation.tr("Font width and roundness settings are only available for some fonts like Google Sans Flex")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "vertical_distribute"
                    text: Translation.tr("Vertical")
                    checked: Config.options.background.widgets.clock.digital.vertical
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.digital.vertical = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "animation"
                    text: Translation.tr("Animate time change")
                    checked: Config.options.background.widgets.clock.digital.animateChange
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.digital.animateChange = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "date_range"
                    text: Translation.tr("Show date")
                    checked: Config.options.background.widgets.clock.digital.showDate
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.digital.showDate = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "activity_zone"
                    text: Translation.tr("Use adaptive alignment")
                    checked: Config.options.background.widgets.clock.digital.adaptiveAlignment
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.digital.adaptiveAlignment = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Aligns the date and quote to left, center or right depending on its position on the screen.")
                    }
                }
            }

            ConfigRow {
                uniform: true

                ConfigSwitch {
                    buttonIcon: "colors"
                    text: Translation.tr("Colorful digits")
                    checked: Config.options.background.widgets.clock.digital.colorful
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.digital.colorful = checked;
                    }
                }
                ConfigSwitch {
                    enabled: !Config.options.background.widgets.clock.digital.vertical
                    buttonIcon: "go_to_line"
                    text: Translation.tr("Show colon")
                    checked: Config.options.background.widgets.clock.digital.showColon
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.digital.showColon = checked;
                    }
                }
            }
            

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Font family")
                text: Config.options.background.widgets.clock.digital.font.family
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.widgets.clock.digital.font.family = text;
                }
            }

            ConfigSlider {
                text: Translation.tr("Font weight")
                value: Config.options.background.widgets.clock.digital.font.weight
                usePercentTooltip: false
                buttonIcon: "format_bold"
                from: 1
                to: 1000
                stopIndicatorValues: [350]
                onValueChanged: {
                    Config.options.background.widgets.clock.digital.font.weight = value;
                }
            }

            ConfigSlider {
                text: Translation.tr("Font size")
                value: Config.options.background.widgets.clock.digital.font.size
                usePercentTooltip: false
                buttonIcon: "format_size"
                from: 50
                to: 700
                stopIndicatorValues: [90]
                onValueChanged: {
                    Config.options.background.widgets.clock.digital.font.size = value;
                }
            }

            ConfigSlider {
                text: Translation.tr("Font width")
                value: Config.options.background.widgets.clock.digital.font.width
                usePercentTooltip: false
                buttonIcon: "fit_width"
                from: 25
                to: 125
                stopIndicatorValues: [100]
                onValueChanged: {
                    Config.options.background.widgets.clock.digital.font.width = value;
                }
            }
            ConfigSlider {
                text: Translation.tr("Font roundness")
                value: Config.options.background.widgets.clock.digital.font.roundness
                usePercentTooltip: false
                buttonIcon: "line_curve"
                from: 0
                to: 100
                onValueChanged: {
                    Config.options.background.widgets.clock.digital.font.roundness = value;
                }
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Cookie clock settings")

            ConfigSpinBox {
                enabled: Config.options.background.widgets.clock.cookie.backgroundStyle !== "shape"
                icon: "add_triangle"
                text: Translation.tr("Sides")
                value: Config.options.background.widgets.clock.cookie.sides
                from: 0
                to: 40
                stepSize: 1
                onValueChanged: {
                    Config.options.background.widgets.clock.cookie.sides = value;
                }
            }

            ConfigSwitch {
                buttonIcon: "autoplay"
                text: Translation.tr("Constantly rotate")
                checked: Config.options.background.widgets.clock.cookie.constantlyRotate
                onCheckedChanged: {
                    Config.options.background.widgets.clock.cookie.constantlyRotate = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical.")
                }
            }

            ConfigRow {

                ConfigSwitch {
                    enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle === "dots" || Config.options.background.widgets.clock.cookie.dialNumberStyle === "full"
                    buttonIcon: "brightness_7"
                    text: Translation.tr("Hour marks")
                    checked: Config.options.background.widgets.clock.cookie.hourMarks
                    onEnabledChanged: {
                        checked = Config.options.background.widgets.clock.cookie.hourMarks;
                    }
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.hourMarks = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons")
                    }
                }

                ConfigSwitch {
                    enabled: Config.options.background.widgets.clock.cookie.dialNumberStyle !== "numbers"
                    buttonIcon: "timer_10"
                    text: Translation.tr("Digits in the middle")
                    checked: Config.options.background.widgets.clock.cookie.timeIndicators
                    onEnabledChanged: {
                        checked = Config.options.background.widgets.clock.cookie.timeIndicators;
                    }
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.timeIndicators = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Can't be turned on when using 'Numbers' dial style for aesthetic reasons")
                    }
                }
            }

            ConfigRow {
                Layout.fillWidth: false
                
                ConfigSwitch {
                    buttonIcon: "wand_stars"
                    text: Translation.tr("Auto style the cookie clock preset")
                    checked: Config.options.background.widgets.clock.cookie.aiStyling
                    onCheckedChanged: {
                        Config.options.background.widgets.clock.cookie.aiStyling = checked;
                    }
                    StyledToolTip {
                        text: Translation.tr("Uses the preferred AI to categorize the wallpaper then picks a preset based on it.\nYou'll need to set API key on the left sidebar first.\nImages are downscaled for performance, but just to be safe,\ndo not select wallpapers with sensitive information.\nBoth AI models does the same thing, but Gemini has strict quotas.")
                    }
                }

                StyledText {
                    Layout.rightMargin: 6
                    text: Translation.tr("with")
                    opacity: Config.options.background.widgets.clock.cookie.aiStyling ? 1 : 0.4
                }

                ConfigSelectionArray {
                    enabled: Config.options.background.widgets.clock.cookie.aiStyling
                    currentValue: Config.options.background.widgets.clock.cookie.aiStylingModel
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.aiStylingModel = newValue;
                    }
                    options: [
                        {
                            displayName: "Gemini",
                            symbol: "google-gemini-symbolic",
                            value: "gemini"
                        },
                        {
                            displayName: "OpenRouter",
                            symbol: "openrouter-symbolic",
                            value: "openrouter"
                        }
                    ]
                }
            }
        }

        

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Dial style")
            ConfigSelectionArray {
                currentValue: Config.options.background.widgets.clock.cookie.dialNumberStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.dialNumberStyle = newValue;
                    if (newValue !== "dots" && newValue !== "full") {
                        Config.options.background.widgets.clock.cookie.hourMarks = false;
                    }
                    if (newValue === "numbers") {
                        Config.options.background.widgets.clock.cookie.timeIndicators = false;
                    }
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "none"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "graph_6",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Full"),
                        icon: "history_toggle_off",
                        value: "full"
                    },
                    {
                        displayName: Translation.tr("Numbers"),
                        icon: "counter_1",
                        value: "numbers"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Hour hand")
            ConfigSelectionArray {
                currentValue: Config.options.background.widgets.clock.cookie.hourHandStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.hourHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Hollow"),
                        icon: "circle",
                        value: "hollow"
                    },
                    {
                        displayName: Translation.tr("Fill"),
                        icon: "eraser_size_5",
                        value: "fill"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Minute hand")

            ConfigSelectionArray {
                currentValue: Config.options.background.widgets.clock.cookie.minuteHandStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.minuteHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Thin"),
                        icon: "line_end",
                        value: "thin"
                    },
                    {
                        displayName: Translation.tr("Medium"),
                        icon: "eraser_size_2",
                        value: "medium"
                    },
                    {
                        displayName: Translation.tr("Bold"),
                        icon: "eraser_size_4",
                        value: "bold"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Second hand")

            ConfigSelectionArray {
                currentValue: Config.options.background.widgets.clock.cookie.secondHandStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.secondHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Line"),
                        icon: "line_end",
                        value: "line"
                    },
                    {
                        displayName: Translation.tr("Dot"),
                        icon: "adjust",
                        value: "dot"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Date style")

            ConfigSelectionArray {
                currentValue: Config.options.background.widgets.clock.cookie.dateStyle
                onSelected: newValue => {
                    Config.options.background.widgets.clock.cookie.dateStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Bubble"),
                        icon: "bubble_chart",
                        value: "bubble"
                    },
                    {
                        displayName: Translation.tr("Border"),
                        icon: "rotate_right",
                        value: "border"
                    },
                    {
                        displayName: Translation.tr("Rect"),
                        icon: "rectangle",
                        value: "rect"
                    }
                ]
            }
        }


        ContentSubsection {
            visible: settingsClock.cookiePresent
            title: Translation.tr("Background style")

            ConfigRow {
                spacing: 10
                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: Config.options.background.widgets.clock.cookie.backgroundStyle
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.backgroundStyle = newValue;
                    }
                    options: [
                        {
                            displayName: "",
                            icon: "block",
                            value: "hide"
                        },
                        {
                            displayName: Translation.tr("Sine"),
                            icon: "waves",
                            value: "sine"
                        },
                        {
                            displayName: Translation.tr("Cookie"),
                            icon: "cookie",
                            value: "cookie"
                        },
                        {
                            displayName: Translation.tr("Shape"),
                            icon: "shape_line",
                            value: "shape"
                        },
                    ]
                }

                RippleButtonWithShape {
                    visible: Config.options.background.widgets.clock.cookie.backgroundStyle == "shape"
                    Layout.fillWidth: false

                    shapeString: Config.options.background.widgets.clock.cookie.backgroundShape
                    implicitWidth: 60
                    extraIcon: "edit"

                    onClicked: {
                        backgroundShapeLoader.active = !backgroundShapeLoader.active;
                    }
                    StyledToolTip {
                        text: Translation.tr("Edit the material shape")
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }   
        }

        Loader { 
            id: backgroundShapeLoader
            active: false
            visible: active
            Layout.fillWidth: true
            sourceComponent: ContentSubsection {
                title: Translation.tr("Background shape")
                
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.clock.cookie.backgroundShape
                    onSelected: newValue => {
                        Config.options.background.widgets.clock.cookie.backgroundShape = newValue;
                    }
                    options: ([ 
                        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill", "Triangle",
                        "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny", "Cookie4Sided", "Cookie6Sided", 
                        "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", 
                        "SoftBurst", "Flower", "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart" 
                    ]).map(icon => { 
                        return { 
                            displayName: "", 
                            shape: icon, 
                            value: icon 
                        } 
                    })
                }
            }
        }
        

        ContentSubsection {
            title: Translation.tr("Quote")

            ConfigSwitch {
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.clock.quote.enable
                onCheckedChanged: {
                    Config.options.background.widgets.clock.quote.enable = checked;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Quote")
                text: Config.options.background.widgets.clock.quote.text
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.widgets.clock.quote.text = text;
                }
            }
        }
    }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Widget: Weather")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.weather.enable
                onCheckedChanged: {
                    Config.options.background.widgets.weather.enable = checked;
                }
            }
            Item {
                Layout.fillWidth: true
            }
            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.weather.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.weather.placementStrategy = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    },
                ]
            }
            RippleButtonWithIcon {
                Layout.alignment: Qt.AlignRight
                materialIcon: "restart_alt"
                mainText: Translation.tr("Reset Position")
                onClicked: {
                    Config.options.background.widgets.weather.placementStrategy = "free";
                    Config.options.background.widgets.weather.x = 50;
                    Config.options.background.widgets.weather.y = 50;
                }
            }
        }
    }

    ContentSection {
        icon: "music_cast"
        title: Translation.tr("Widget: Media")
        tooltip: Translation.tr("You can reset the media player by middle-clicking on the widget in case of media source errors")

        ConfigRow {
            Layout.fillWidth: true

            ConfigSwitch {
                Layout.fillWidth: false
                buttonIcon: "check"
                text: Translation.tr("Enable")
                checked: Config.options.background.widgets.media.enable
                onCheckedChanged: {
                    Config.options.background.widgets.media.enable = checked;
                }
            }
            
            RippleButtonWithShape {
                shapeString: Config.options.background.widgets.media.backgroundShape
                implicitWidth: 60
                extraIcon: "edit"

                onClicked: {
                    mediaBackgroundShapeLoader.active = !mediaBackgroundShapeLoader.active;
                }
                StyledToolTip {
                    text: Translation.tr("Edit the material shape")
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: Config.options.background.widgets.media.placementStrategy
                onSelected: newValue => {
                    Config.options.background.widgets.media.placementStrategy = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Draggable"),
                        icon: "drag_pan",
                        value: "free"
                    },
                    {
                        displayName: Translation.tr("Least busy"),
                        icon: "category",
                        value: "leastBusy"
                    },
                    {
                        displayName: Translation.tr("Most busy"),
                        icon: "shapes",
                        value: "mostBusy"
                    }
                ]
            }
            RippleButtonWithIcon {
                Layout.alignment: Qt.AlignRight
                materialIcon: "restart_alt"
                mainText: Translation.tr("Reset Position")
                onClicked: {
                    Config.options.background.widgets.media.placementStrategy = "free";
                    Config.options.background.widgets.media.x = 1600;
                    Config.options.background.widgets.media.y = 50;
                }
            }
        }


        Loader { 
            id: mediaBackgroundShapeLoader
            active: false
            visible: active
            Layout.fillWidth: true
            sourceComponent: ContentSubsection {
                title: Translation.tr("Background shape")
                
                ConfigSelectionArray {
                    currentValue: Config.options.background.widgets.media.backgroundShape
                    onSelected: newValue => {
                        Config.options.background.widgets.media.backgroundShape = newValue;
                    }
                    options: ([ 
                        "Circle", "Square", "Slanted", "Arch", "Arrow", "SemiCircle", "Oval", "Pill", "Triangle",
                        "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny", "Cookie4Sided", "Cookie6Sided", 
                        "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "Ghostish", "Clover4Leaf", "Clover8Leaf", "Burst", 
                        "SoftBurst", "Flower", "Puffy", "PuffyDiamond", "PixelCircle", "Bun", "Heart" 
                    ]).map(icon => { 
                        return { 
                            displayName: "", 
                            shape: icon, 
                            value: icon 
                        } 
                    })
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "opacity"
                text: Translation.tr("Use album colors")
                checked: Config.options.background.widgets.media.useAlbumColors
                onCheckedChanged: {
                    Config.options.background.widgets.media.useAlbumColors = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colors"
                text: Translation.tr("Tint art cover")
                checked: Config.options.background.widgets.media.tintArtCover
                onCheckedChanged: {
                    Config.options.background.widgets.media.tintArtCover = checked;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "block"
                text: Translation.tr("Hide all controls")
                checked: Config.options.background.widgets.media.hideAllButtons
                onCheckedChanged: {
                    Config.options.background.widgets.media.hideAllButtons = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Buttons will only be visible on hover")
                }
            }
            ConfigSwitch {
                buttonIcon: "skip_previous"
                text: Translation.tr("Show previous toggle")
                checked: Config.options.background.widgets.media.showPreviousToggle
                onCheckedChanged: {
                    Config.options.background.widgets.media.showPreviousToggle = checked;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Glow effect")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "backlight_high"
                    text: Translation.tr("Enable")
                    checked: Config.options.background.widgets.media.glow.enable
                    onCheckedChanged: {
                        Config.options.background.widgets.media.glow.enable = checked;
                    }
                }
                ConfigSpinBox {
                    from: 5
                    to: 100
                    stepSize: 5
                    icon: "brightness_5"
                    text: Translation.tr("Brightness (%)")
                    value: Config.options.background.widgets.media.glow.brightness
                    onValueChanged: {
                        Config.options.background.widgets.media.glow.brightness = value;
                    }
                }
            }
        }
    }


}
