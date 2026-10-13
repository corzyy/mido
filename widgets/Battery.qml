import QtQuick
import Quickshell.Services.UPower
import qs.core
import qs.ui

// Battery icon; hidden on machines without one. Right click shows or hides the percentage
// (`showPercentage` sets the initial state). Turns urgent at or below `low` (default 15%).
BarWidget {
  id: root

  property bool showPercentage: setting("showPercentage", false) === true

  readonly property var device: UPower.displayDevice
  readonly property bool present: device !== null && device.isPresent
  readonly property real fraction: present ? device.percentage : 0
  readonly property bool onBattery: present && UPower.onBattery
  readonly property bool full: present && device.state === UPowerDeviceState.FullyCharged
  readonly property bool low: present && onBattery && Math.round(fraction * 100) <= Number(setting("low", 15))

  visible: present
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  function icon() {
    if (!present) return ""
    var charging = [0xf089c, 0xf0086, 0xf0087, 0xf0088, 0xf089d, 0xf0089, 0xf089e, 0xf008a, 0xf008b, 0xf0085]
    var discharging = [0xf007a, 0xf007b, 0xf007c, 0xf007d, 0xf007e, 0xf007f, 0xf0080, 0xf0081, 0xf0082, 0xf0079]
    var index = Util.clamp(Math.floor(fraction * 10), 0, 9)
    if (full) return Util.glyph(0xf0085)
    return Util.glyph((onBattery ? discharging : charging)[index])
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.icon()
    labelText: root.showPercentage && !root.vertical ? Math.round(root.fraction * 100) + "%" : ""
    slotSize: Style.bar.iconSlot * (root.showPercentage && !root.vertical ? 2 : 1)
    active: root.low
    onPressed: function(b) {
      if (b === Qt.RightButton) root.showPercentage = !root.showPercentage
    }
  }
}
