import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.core
import qs.ui

// The active keyboard layout as a short code ("US", "DE"). Only shown when the keyboard
// has more than one layout. Left click switches to the next layout.
BarWidget {
  id: root

  property var layouts: []
  property int index: 0
  readonly property string label: layouts.length > 0 ? String(layouts[Math.min(index, layouts.length - 1)]).toUpperCase() : ""

  function refresh() {
    if (!query.running) query.running = true
  }

  visible: layouts.length > 1
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  Component.onCompleted: refresh()

  Process {
    id: query
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var keyboards = JSON.parse(text).keyboards || []
          var main = keyboards.filter(function(k) { return k.main })[0] || keyboards[0]
          if (!main) return
          root.layouts = String(main.layout || "").split(",").filter(function(l) { return l !== "" })
          // Hyprland names the active layout in full ("English (US)"); the list says which slot it is.
          root.index = main.active_layout_index !== undefined ? main.active_layout_index : root.index
        } catch (e) {
          console.warn("keyboard-layout: " + e)
        }
      }
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activelayout") root.refresh()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    tooltipText: "Keyboard layout"
    onPressed: {
      Util.run(["hyprctl", "switchxkblayout", "all", "next"])
      root.refresh()
    }
  }
}
