pragma Singleton
import QtQuick
import Quickshell

// Maps the `id` used in settings.json's bar.layout to a widget file.
// To add a widget: create widgets/<Name>.qml (extend BarWidget) and list it here.
Singleton {
  readonly property var widgets: ({
    "active-window": "ActiveWindow",
    "audio": "Audio",
    "battery": "Battery",
    "bluetooth": "Bluetooth",
    "clock": "Clock",
    "indicators": "Indicators",
    "keyboard-layout": "KeyboardLayout",
    "media": "Media",
    "menu": "Menu",
    "microphone": "Microphone",
    "monitor": "Monitor",
    "network": "Network",
    "spacer": "Spacer",
    "system-update": "SystemUpdate",
    "tray": "Tray",
    "weather": "Weather",
    "workspaces": "Workspaces"
  })

  function canonical(id) {
    return String(id || "")
  }

  function url(id) {
    var name = widgets[canonical(id)]
    if (!name) return ""
    return Qt.resolvedUrl("../../widgets/" + name + ".qml")
  }
}
