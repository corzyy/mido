pragma Singleton
import QtQuick

// Border descriptions for surfaces and controls: { color, width }. The states
// follow Style's tokens: normal, hover-cursor, selected and focus.
QtObject {
  function none() { return { color: "transparent", width: 0 } }

  function flat(color, width) { return { color: color || "transparent", width: Math.max(0, Number(width) || 0) } }

  function controlSpec(state, foreground, accent) {
    var fg = foreground || Colors.foreground
    if (state === "focus") return flat(Style.focusBorderFor(fg, accent), Style.focusBorderWidth)
    if (state === "hover-cursor" || state === "hover" || state === "hot") return flat(Style.hoverBorderFor(fg, accent), Style.hoverBorderWidth)
    if (state === "selected") return flat(Style.selectedBorderFor(fg, accent), Style.selectedBorderWidth)
    return flat(Style.normalBorderFor(fg, accent), Style.normalBorderWidth)
  }

  function controlHasWidth(state) { return controlSpec(state).width > 0 }

  function surfaceSpec(section, token, color, width) { return flat(color, width) }

  function localOrSurfaceSpec(section, token, localColor, defaultColor, width) { return flat(localColor, width) }

  function top(spec) { return spec ? spec.width : 0 }
  function right(spec) { return spec ? spec.width : 0 }
  function bottom(spec) { return spec ? spec.width : 0 }
  function left(spec) { return spec ? spec.width : 0 }
  function uniformWidth(spec) { return spec ? spec.width : 0 }
  function color(spec) { return spec ? spec.color : "transparent" }
  function canUseNative(spec) { return true }
  function needsOverlay(spec) { return false }
}
