import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    visible: true
    color: "transparent"
    screen: Quickshell.screens[Number(Quickshell.env("HYPR_DISINTEGRATE_MONITOR"))]
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hypr-window-disintegrate-debug"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Image {
        anchors.leftMargin: Number(Quickshell.env("HYPR_DISINTEGRATE_X")) - Number(Quickshell.env("HYPR_DISINTEGRATE_MONITOR_X"))
        anchors.topMargin: Number(Quickshell.env("HYPR_DISINTEGRATE_Y")) - Number(Quickshell.env("HYPR_DISINTEGRATE_MONITOR_Y"))
        width: Number(Quickshell.env("HYPR_DISINTEGRATE_WIDTH"))
        height: Number(Quickshell.env("HYPR_DISINTEGRATE_HEIGHT"))
        source: "file://" + Quickshell.env("HYPR_DISINTEGRATE_IMAGE")
        fillMode: Image.Stretch
    }

    Timer {
        interval: Number(Quickshell.env("HYPR_DISINTEGRATE_DURATION"))
        running: true
        onTriggered: Qt.quit()
    }
}
