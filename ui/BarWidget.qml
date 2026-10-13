import QtQuick
import qs.core

// Base item for every bar widget. The bar injects:
//   bar       the Bar (colors, fontFamily, position, showTooltip, run, ...)
//   settings  this widget's entry from settings.json's bar.layout
Item {
  property var bar: null
  property string moduleName: ""
  property var settings: ({})
  // The widget's BarPopup, if it has one: `mido ipc call bar popup <id>` toggles it.
  property var popupTarget: null

  // Bar geometry, lifted off the host so widgets can pick between
  // horizontal and vertical layouts without a ternary on `bar` every time.
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : Style.bar.sizeHorizontal

  implicitHeight: barSize

  // A value from this widget's settings entry, or the fallback.
  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }
}
