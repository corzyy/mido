import QtQuick
import Quickshell.Io
import qs.core
import qs.ui

// Shows an icon while dnf has updates waiting (checked every `interval` seconds, default 6 hours).
// Left click runs the upgrade in a terminal, then checks again.
BarWidget {
  id: root

  property int pending: 0

  function refresh() {
    if (!check.running) check.running = true
  }

  visible: pending > 0
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: check
    // dnf lists one "name version repo" line per package; the exit status is not a count.
    command: ["bash", "-c", "dnf check-upgrade -q 2>/dev/null | awk 'NF == 3 && $1 ~ /\\./' | wc -l"]
    stdout: StdioCollector {
      onStreamFinished: root.pending = parseInt(text) || 0
    }
  }

  Process {
    id: upgrade
    command: ["bash", "-c", Util.terminalCommand("sudo dnf upgrade", true)]
    onExited: root.refresh()
  }

  Timer {
    interval: Number(root.setting("interval", 21600)) * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Util.glyph(0xf021)
    slotSize: Style.bar.statusSlot
    tooltipText: root.pending + " pending update" + (root.pending === 1 ? "" : "s")
    onPressed: if (!upgrade.running) upgrade.running = true
  }
}
