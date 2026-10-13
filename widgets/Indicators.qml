import QtQuick
import Quickshell.Io
import qs.core
import qs.ui

// State indicators: screen recording, stay awake and night light. An indicator shows while it is
// active; hovering the strip next to them reveals the inactive ones, dimmed, so they can be turned
// on. `alwaysShow` keeps the inactive ones visible, and `items` picks a subset, e.g.
// ["ScreenRecording", "StayAwake"].
BarWidget {
  id: root

  readonly property var defaultItems: ["ScreenRecording", "NightLight", "StayAwake"]
  readonly property var itemIds: {
    var configured = setting("items", [])
    return configured && configured.length > 0 ? configured : defaultItems
  }
  readonly property bool alwaysShow: setting("alwaysShow", false) === true

  property bool recording: false
  property bool stayAwake: false
  property bool nightLight: false
  property bool nightLightInstalled: false

  property bool areaHovered: false
  readonly property bool revealInactive: alwaysShow || areaHovered

  // Everything an indicator needs, by id. `reveal` marks the ones with something to switch on.
  readonly property var catalog: ({
    "ScreenRecording": {
      glyph: 0xf0ec2, active: recording, available: true,
      activeTip: "Stop recording", inactiveTip: "Screen Recording",
      press: function() {
        if (root.recording) Util.run(["pkill", "-SIGINT", "-x", "gpu-screen-recorder"])
        else Util.runShell("mido ipc call menu open trigger/capture")
      }
    },
    "StayAwake": {
      glyph: 0xf0176, active: stayAwake, available: true,
      activeTip: "Allow Idle Lock & Screensaver", inactiveTip: "Stay Awake",
      press: function() { root.stayAwake = !root.stayAwake }
    },
    "NightLight": {
      glyph: 0xf050e, active: nightLight, available: nightLightInstalled,
      activeTip: "Day Light", inactiveTip: "Night Light",
      press: function() { root.nightLight = !root.nightLight }
    }
  })

  readonly property var entries: itemIds.map(function(id) { return catalog[id] ? Object.assign({ id: id }, catalog[id]) : null })
    .filter(function(e) { return e !== null && e.available })
  readonly property var activeEntries: entries.filter(function(e) { return e.active })
  readonly property var inactiveEntries: entries.filter(function(e) { return !e.active })

  implicitWidth: vertical ? barSize : layout.implicitWidth
  implicitHeight: vertical ? layout.implicitHeight : barSize

  // Whether a gpu-screen-recorder is running, polled while nothing else tells us.
  Timer {
    interval: 2000
    running: root.itemIds.indexOf("ScreenRecording") !== -1
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!recordingProbe.running) recordingProbe.running = true
  }

  Process {
    id: recordingProbe
    command: ["pgrep", "-x", "gpu-screen-recorder"]
    onExited: function(code) { root.recording = code === 0 }
  }

  // An idle and sleep inhibitor, held for as long as stay awake is on.
  Process {
    id: inhibitor
    running: root.stayAwake
    command: ["systemd-inhibit", "--what=idle:sleep", "--who=mido", "--why=Stay awake", "--mode=block", "sleep", "infinity"]
  }

  Process {
    id: sunset
    running: root.nightLight
    command: ["hyprsunset", "-t", "4500"]
    onExited: root.nightLight = false
  }

  Process {
    id: sunsetProbe
    running: true
    command: ["bash", "-c", "command -v hyprsunset"]
    onExited: function(code) { root.nightLightInstalled = code === 0 }
  }

  Timer {
    id: hideTimer
    interval: 120
    onTriggered: root.areaHovered = false
  }

  function setHovered(hovered) {
    if (hovered) {
      hideTimer.stop()
      areaHovered = true
    } else {
      hideTimer.restart()
    }
  }

  HoverHandler {
    onHoveredChanged: root.setHovered(hovered)
  }

  // A hover target that is always there, so the inactive indicators can be reached.
  Item {
    id: strip
    visible: !root.revealInactive && root.activeEntries.length === 0 && root.inactiveEntries.length > 0
    width: root.vertical ? root.barSize : Style.space(10)
    height: root.vertical ? Style.space(10) : root.barSize
  }

  Grid {
    id: layout
    anchors.centerIn: parent
    flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
    rows: root.vertical ? -1 : 1
    columns: root.vertical ? 1 : -1

    Repeater {
      model: root.revealInactive ? root.inactiveEntries : []
      delegate: indicator
    }

    Repeater {
      model: root.activeEntries
      delegate: indicator
    }
  }

  Component {
    id: indicator

    BarIconButton {
      required property var modelData

      bar: root.bar
      text: Util.glyph(modelData.glyph)
      dimmed: !modelData.active
      useActiveColor: false
      slotSize: Style.bar.statusSlot
      tooltipText: modelData.active ? modelData.activeTip : modelData.inactiveTip
      onPressed: modelData.press()
    }
  }
}
