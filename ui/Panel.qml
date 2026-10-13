import QtQuick
import qs.core

// Base item for a bar widget that owns a KeyboardPanel: it holds the open state and gives
// `mido ipc call bar popup <id>` something to toggle.
BarWidget {
  id: root

  property bool opened: false
  property bool popoutSwitching: false
  property bool popoutSwitchClosing: false
  readonly property color barForeground: bar ? bar.barForeground : Colors.foreground

  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened ? close() : open() }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(function() { popoutSwitchClosing = false })
  }

  // Switching straight to a neighbouring panel is not supported.
  function switchPanel(direction) { return false }

  // Lets the bar's IPC reach `toggle()`.
  popupTarget: root
}
