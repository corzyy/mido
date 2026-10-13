import QtQuick
import qs.core
import qs.ui

// The menu button. Left click runs `onClick` (default: opens the main menu), right click runs `onRightClick`
// (default: a terminal). Both are shell command lines.
BarWidget {
  id: root

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontFamily: "omarchy"
    onPressed: function(b) {
      if (b === Qt.RightButton) Util.runShell(root.setting("onRightClick", "xdg-terminal-exec"))
      else if (b === Qt.LeftButton) Util.runShell(root.setting("onClick", "mido ipc call menu toggle"))
    }
  }
}
