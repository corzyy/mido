import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.core
import qs.ui

// Hyprland workspaces 1-5 plus any occupied up to 10. Empty ones are dimmed.
// The focused one shows a layout glyph (a square for tiling) instead of its number.
// Click focuses, wheel steps through the row.
BarWidget {
  id: root

  property real wheelAccumulator: 0

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++)
      if (values[i].id === id) return values[i]
    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(a, b) { return a - b })
    return ids
  }

  function focusedId() {
    return Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
  }

  function focus(id) {
    Util.run(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = \"" + id + "\" })"])
  }

  function scroll(delta) {
    var wheel = Util.wheelSteps(wheelAccumulator, delta)
    wheelAccumulator = wheel.remainder
    if (wheel.steps === 0) return

    var ids = workspaceIds()
    var index = ids.indexOf(focusedId())
    if (index === -1) return
    var target = ids[Util.clamp(index - wheel.steps, 0, ids.length - 1)]
    if (target !== ids[index]) focus(target)
  }

  readonly property real trailingGap: vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: root.focusedId() === modelData

        bar: root.bar
        text: focused ? Util.glyph(0xf14fb) : (modelData === 10 ? "0" : String(modelData))
        // The layout glyph is an icon in an icon font; the figures are text.
        centerFigures: !focused
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() {
          if (!focused) root.focus(modelData)
        }
        onWheelMoved: function(delta) { root.scroll(delta) }
      }
    }
  }
}
