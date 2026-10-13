import QtQuick
import qs.core

// A clickable bar label: text or one icon glyph, tinted by state. Single icon
// glyphs are fitted to their painted bounds (OpticalGlyph) so every icon has
// the same visual size and centre regardless of the font's metrics.
Item {
  id: root

  property var bar: null
  property string text: ""
  property string fontFamily: bar ? bar.fontFamily : Style.fontFamily
  property real fontSize: Style.fontSize
  property color foreground: bar ? bar.barForeground : Colors.foreground
  property color activeColor: bar ? bar.urgent : Colors.urgent
  property bool active: false
  property real horizontalMargin: 8.5
  property real verticalPadding: 6
  property real fixedWidth: -1
  property real fixedHeight: -1
  property real textRotation: 0
  property bool keepSpace: false
  property bool dimmed: false
  property bool interactive: true
  property bool pressable: true
  property bool useActiveColor: true
  // Off for icon-font labels, whose figure metrics say nothing about the glyph.
  property bool centerFigures: true
  property bool labelVisible: true
  property bool hasVisualContent: text !== ""
  property string tooltipText: ""

  signal pressed(int button)
  signal wheelMoved(int delta)

  function triggerPress(button) {
    if (root.bar) root.bar.hideTooltip(root)
    root.pressed(button)
  }

  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : Style.bar.sizeHorizontal
  readonly property real scaledHorizontalMargin: Style.spaceReal(horizontalMargin)
  readonly property real scaledVerticalPadding: Style.spaceReal(verticalPadding)
  readonly property bool tooltipHovered: visible && interactive && mouseArea.containsMouse
  // Width of the painted label; zero on icon-only buttons.
  readonly property real labelWidth: label.visible ? label.implicitWidth : 0
  readonly property bool iconLabel: labelVisible && isIconGlyph(text)

  function isIconGlyph(value) {
    var text = String(value || "")
    if (!text) return false
    var code = text.codePointAt(0)
    if (text.length !== (code > 0xffff ? 2 : 1)) return false
    return (code >= 0xe000 && code <= 0xf8ff)
      || (code >= 0xf0000 && code <= 0xffffd)
      || (code >= 0x100000 && code <= 0x10fffd)
      || (code >= 0x2190 && code <= 0x2bff)
  }

  onVisibleChanged: if (!visible && bar) bar.hideTooltip(root)

  visible: hasVisualContent || keepSpace
  opacity: !hasVisualContent ? 0 : (dimmed ? 0.45 : 1)
  implicitWidth: fixedWidth > 0 ? fixedWidth
    : (vertical ? barSize : (iconLabel ? Style.bar.iconSlot : Math.max(12, label.implicitWidth + scaledHorizontalMargin * 2)))
  implicitHeight: fixedHeight > 0 ? fixedHeight
    : (vertical ? (iconLabel ? Style.bar.iconSlot : Math.max(12, label.implicitHeight + scaledVerticalPadding * 2)) : barSize)

  Behavior on opacity {
    NumberAnimation { duration: Style.duration(140); easing.type: Easing.OutCubic }
  }

  Text {
    id: label
    textFormat: Text.PlainText
    visible: root.labelVisible && !root.iconLabel
    anchors.centerIn: parent
    // Centering the line box puts the figures above the bar's middle, since
    // the box keeps room for descenders. Center the figure height instead, so
    // labels line up with the icons beside them.
    anchors.verticalCenterOffset: !root.centerFigures || root.vertical || root.text.indexOf("\n") !== -1
      ? 0
      : (labelMetrics.descent - labelMetrics.ascent + labelMetrics.tightBoundingRect("0").height) / 2
    text: root.text
    color: root.active && root.useActiveColor ? root.activeColor : root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    renderType: Text.NativeRendering
    rotation: root.textRotation
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
      ColorAnimation { duration: Style.duration(160) }
    }
  }

  FontMetrics {
    id: labelMetrics
    font: label.font
  }

  Loader {
    id: iconLoader
    active: root.iconLabel
    width: Style.bar.iconCanvas
    height: Style.bar.iconCanvas
    x: (root.width - width) / 2
    y: (root.height - height) / 2
    sourceComponent: Component {
      OpticalGlyph {
        text: root.text
        fontFamily: root.fontFamily
        fontSize: root.fontSize
        paintedSize: Style.bar.iconSize
        color: root.active && root.useActiveColor ? root.activeColor : root.foreground
        rotation: root.textRotation
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: root.pressable ? Qt.PointingHandCursor : Qt.ArrowCursor
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltipText)
    onExited: if (root.bar) root.bar.hideTooltip(root)
    onClicked: function(mouse) { if (root.pressable) root.triggerPress(mouse.button) }
    onWheel: function(wheel) { root.wheelMoved(wheel.angleDelta.y) }
  }
}
