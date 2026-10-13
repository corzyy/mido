import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.core
import qs.ui

// Default input. Left click mutes, middle click opens the audio panel, the wheel changes the level.
// Turns urgent while an application is recording and the microphone is live.

BarWidget {
  id: root

  readonly property var source: Pipewire.defaultAudioSource
  readonly property bool muted: source && source.audio ? source.audio.muted : true
  readonly property real volume: source && source.audio ? source.audio.volume : 0
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []

  readonly property var activeStreams: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (!node || !node.isStream || node.isSink !== false || node.audio?.muted) continue
      // The shell's own level meters are not an app using the microphone.
      if (node.name === "quickshell" || node.name === "quickshell-peak-monitor") continue
      list.push(node)
    }
    return list
  }

  readonly property bool inUse: activeStreams.length > 0 && !muted

  visible: source !== null
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function toggleMute() {
    if (source && source.audio) source.audio.muted = !source.audio.muted
  }

  PwObjectTracker { objects: root.source ? [root.source] : [] }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.muted ? "󰍭" : "󰍬"
    active: root.inUse
    tooltipText: root.muted ? "Microphone muted" : (root.inUse ? "Microphone in use" : "Microphone live")
    onPressed: function(b) {
      if (b === Qt.MiddleButton) { if (root.bar) root.bar.togglePopup("audio") }
      else root.toggleMute()
    }
    onWheelMoved: function(delta) {
      var step = 0.05
      if (!root.source || !root.source.audio) return
      root.source.audio.volume = Math.max(0, Math.min(1, root.volume + (delta > 0 ? step : -step)))
    }
  }
}
