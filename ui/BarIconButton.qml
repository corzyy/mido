import QtQuick
import qs.core

// An icon button: the glyph is fitted to Style.bar.iconSize inside a canvas,
// centred in a square slot. `labelText` adds a text label beside the icon
// (the battery percentage).
WidgetButton {
  id: root

  property real slotSize: Style.bar.iconSlot
  property real opticalSize: Style.bar.iconCanvas
  readonly property real visualIconSize: Style.bar.iconSize
  readonly property real canvasSize: Math.max(visualIconSize, opticalSize)
  property string labelText: ""

  labelVisible: false
  hasVisualContent: text !== "" || labelText !== ""
  fontSize: Style.bar.iconFont
  fixedWidth: vertical ? -1 : slotSize
  fixedHeight: vertical ? slotSize : -1

  Item {
    id: content
    // Exact coordinates preserve the center of odd-width slots.
    x: (root.width - width) / 2
    y: (root.height - height) / 2
    width: root.canvasSize + (label.visible ? label.implicitWidth + Style.space(4) : 0)
    height: root.canvasSize

    Text {
      id: label
      visible: root.labelText !== ""
      textFormat: Text.PlainText
      text: root.labelText
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
      color: root.active && root.useActiveColor ? root.activeColor : root.foreground
      y: (parent.height - height) / 2
        + (labelMetrics.descent - labelMetrics.ascent + labelMetrics.tightBoundingRect("0").height) / 2
      renderType: Text.NativeRendering
    }

    FontMetrics {
      id: labelMetrics
      font: label.font
    }

    OpticalGlyph {
      x: label.visible ? label.implicitWidth + Style.space(4) : 0
      width: root.canvasSize
      height: root.canvasSize
      text: root.text
      fontFamily: root.fontFamily
      fontSize: root.fontSize
      paintedSize: root.visualIconSize
      color: root.active && root.useActiveColor ? root.activeColor : root.foreground
      rotation: root.textRotation
    }
  }
}
