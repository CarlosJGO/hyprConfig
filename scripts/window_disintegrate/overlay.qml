import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: true
    color: "transparent"
    mask: Region {
        width: 0
        height: 0
    }
    readonly property var targetScreen: {
        const wanted = Quickshell.env("HYPR_DISINTEGRATE_MONITOR_NAME")
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; ++i) {
            if (screens[i].name === wanted)
                return screens[i]
        }
        const idx = Number(Quickshell.env("HYPR_DISINTEGRATE_MONITOR"))
        return screens[idx] || screens[0]
    }
    screen: root.targetScreen
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hypr-window-disintegrate"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    readonly property real durationMs: Number(Quickshell.env("HYPR_DISINTEGRATE_DURATION"))
    readonly property string imagePath: Quickshell.env("HYPR_DISINTEGRATE_IMAGE")
    readonly property string readyFile: Quickshell.env("HYPR_DISINTEGRATE_READY_FILE")
    readonly property string effectName: Quickshell.env("HYPR_CLOSE_EFFECT") || "desintegra"
    readonly property string shaderFile: Quickshell.env("HYPR_CLOSE_SHADER") || "disintegrate.frag.qsb"
    readonly property real winX: Number(Quickshell.env("HYPR_DISINTEGRATE_X")) - Number(Quickshell.env("HYPR_DISINTEGRATE_MONITOR_X"))
    readonly property real winY: Number(Quickshell.env("HYPR_DISINTEGRATE_Y")) - Number(Quickshell.env("HYPR_DISINTEGRATE_MONITOR_Y"))
    readonly property real winW: Number(Quickshell.env("HYPR_DISINTEGRATE_WIDTH"))
    readonly property real winH: Number(Quickshell.env("HYPR_DISINTEGRATE_HEIGHT"))
    property bool signaledReady: false

    function finish() {
        if (root.imagePath)
            Quickshell.execDetached(["rm", "-f", root.imagePath])
        Qt.quit()
    }

    function signalReady() {
        if (root.signaledReady)
            return
        root.signaledReady = true
        if (root.readyFile && root.readyFile.length > 0)
            Quickshell.execDetached(["sh", "-c", "printf ready > \"$1\"", "sh", root.readyFile])
    }

    // Off-screen source for the shader.
    Image {
        id: capturedWindow
        x: root.width + 32
        y: 0
        width: root.winW
        height: root.winH
        source: "file://" + root.imagePath
        fillMode: Image.Stretch
        asynchronous: false
        onStatusChanged: {
            if (status === Image.Ready) {
                // Plate is up — tell Python it can hide the real window.
                root.signalReady()
                frameTimer.start()
            } else if (status === Image.Error) {
                root.signalReady()
                root.finish()
            }
        }
    }

    ShaderEffectSource {
        id: capturedSource
        sourceItem: capturedWindow
        hideSource: true
        live: false
        recursive: false
    }

    // Covers the live window until (and briefly after) the shader starts.
    Image {
        id: solidPlate
        x: root.winX
        y: root.winY
        width: root.winW
        height: root.winH
        source: capturedWindow.source
        fillMode: Image.Stretch
        visible: capturedWindow.status === Image.Ready
        z: 1
    }

    ShaderEffect {
        id: effect
        x: root.winX
        y: root.winY
        width: root.winW
        height: root.winH
        visible: false
        z: 2
        opacity: 1.0
        property variant source: capturedSource
        property real progress: 0.0
        property real blockSize: Number(Quickshell.env("HYPR_DISINTEGRATE_BLOCK"))
        property real intensity: Number(Quickshell.env("HYPR_DISINTEGRATE_INTENSITY"))
        property real seed: Number(Quickshell.env("HYPR_DISINTEGRATE_SEED"))
        fragmentShader: Qt.resolvedUrl(root.shaderFile)

        onStatusChanged: {
            if (status === ShaderEffect.Error) {
                console.warn(root.effectName, "shader error:", log)
                fallbackFade.start()
            }
        }
    }

    NumberAnimation {
        id: progressAnim
        target: effect
        property: "progress"
        from: 0.0
        to: 1.0
        duration: root.durationMs
        // Tornado: linear so spin/curl start immediately (no whip delay).
        easing.type: root.effectName === "tornado" ? Easing.Linear : Easing.OutCubic
    }

    NumberAnimation {
        id: fallbackFade
        target: solidPlate
        property: "opacity"
        from: 1.0
        to: 0.0
        duration: root.durationMs
        easing.type: Easing.OutCubic
        onStarted: effect.visible = false
    }

    Timer {
        id: frameTimer
        interval: 16
        repeat: false
        onTriggered: {
            capturedSource.scheduleUpdate()
            if (effect.status === ShaderEffect.Error) {
                fallbackFade.start()
                return
            }
            effect.progress = 0.0
            effect.visible = true
            progressAnim.start()
            // Keep the plate under the shader for a couple frames so any
            // first-frame mismatch never shows as a blink.
            hidePlateTimer.start()
        }
    }

    Timer {
        id: hidePlateTimer
        interval: 48
        repeat: false
        onTriggered: solidPlate.visible = false
    }

    Timer {
        interval: root.durationMs + 80
        running: true
        repeat: false
        onTriggered: root.finish()
    }
}
