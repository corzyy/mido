pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colors, written by matugen to generated/colors.json (template: matugen/colors.json).
// The defaults apply until that file exists. Reassigned live when matugen re-runs.
Singleton {
  id: root

  property color background: "#101315"
  property color foreground: "#cacccc"
  property color accent: "#cacccc"
  property color urgent: "#a55555"
  property color muted: "#707880"

  // The surfaces popups are drawn with.
  readonly property QtObject popups: QtObject {
    property color background: root.background
    property color text: root.foreground
    property color border: root.accent
  }
  readonly property QtObject tooltip: QtObject {
    property color background: root.background
    property color text: root.foreground
    property color border: root.foreground
  }

  function apply(c) {
    if (c.surface) background = c.surface
    if (c.on_surface) foreground = c.on_surface
    if (c.primary) accent = c.primary
    if (c.error) urgent = c.error
    if (c.outline) muted = c.outline
  }

  FileView {
    path: Quickshell.shellPath("generated/colors.json")
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        root.apply(JSON.parse(text()))
      } catch (e) {
        console.warn("generated/colors.json: " + e)
      }
    }
  }
}
