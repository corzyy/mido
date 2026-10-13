pragma Singleton
import QtQuick
import Quickshell

// Structural tokens (sizes, fonts, timing), taken from Omarchy's Style.bar.
// Everything scales with the font size (12px is the reference), like Omarchy's
// scale-with-font. Colors live in Colors.
Singleton {
  id: root

  readonly property string fontFamily: Config.bar.font
  readonly property int fontSize: Config.bar.fontSize
  readonly property real fontScale: Math.max(1 / 12, fontSize / 12)
  readonly property int cornerRadius: 0

  readonly property FontLoader omarchyFont: FontLoader {
    source: Qt.resolvedUrl("../assets/omarchy.ttf")
  }

  function spaceReal(px) {
    var n = Number(px)
    return isFinite(n) && n > 0 ? n * fontScale : 0
  }

  function space(px) {
    var n = spaceReal(px)
    return n <= 0 ? 0 : Math.max(1, Math.round(n))
  }

  function token(base) {
    return Math.max(1, Math.round(base * fontScale))
  }

  function duration(ms) {
    return ms
  }

  readonly property QtObject bar: QtObject {
    readonly property int sizeHorizontal: Math.max(1, Math.round(Number(Config.bar.height) * root.fontScale))
    readonly property int sizeVertical: root.token(28)
    readonly property int iconSlot: root.token(27)
    readonly property int iconCanvas: root.token(16)
    readonly property int iconFont: root.token(13)
    readonly property int iconSize: Math.min(iconCanvas, root.token(12))
    readonly property int statusSlot: root.token(21)
  }

  // The base font size, which every font token and spacing scales from.
  readonly property int fontBaseSize: fontSize

  readonly property int gapsOut: 5
  property bool reduceMotion: false

  // Interaction states. Fills and borders are the foreground at a fixed alpha.
  readonly property real normalFillAlpha: 0.04
  readonly property real hoverFillAlpha: 0.08
  readonly property real selectedFillAlpha: 0.18
  readonly property real pressedFillAlpha: 0.22
  readonly property real focusFillAlpha: hoverFillAlpha
  readonly property real selectionFillAlpha: 0.35
  readonly property real normalBorderAlpha: 0.4
  readonly property real hoverBorderAlpha: 0.25
  readonly property real selectedBorderAlpha: 1.0
  readonly property real focusBorderAlpha: hoverBorderAlpha
  readonly property int normalBorderWidth: 1
  readonly property int hoverBorderWidth: 1
  readonly property int selectedBorderWidth: 0
  readonly property int focusBorderWidth: 1

  function normalStateColor(foreground, accent) { return foreground || Colors.foreground }
  function hoverStateColor(foreground, accent) { return foreground || Colors.foreground }
  function selectedStateColor(foreground, accent) { return foreground || Colors.foreground }
  function pressedStateColor(foreground, accent) { return foreground || Colors.foreground }
  function focusStateColor(foreground, accent) { return foreground || Colors.foreground }
  function selectionStateColor(foreground, accent) { return foreground || Colors.foreground }

  function normalFillFor(foreground, accent) { return Util.alpha(normalStateColor(foreground, accent), normalFillAlpha) }
  function hoverFillFor(foreground, accent) { return Util.alpha(hoverStateColor(foreground, accent), hoverFillAlpha) }
  function selectedFillFor(foreground, accent) { return Util.alpha(selectedStateColor(foreground, accent), selectedFillAlpha) }
  function pressedFillFor(foreground, accent) { return Util.alpha(pressedStateColor(foreground, accent), pressedFillAlpha) }
  function focusFillFor(foreground, accent) { return Util.alpha(focusStateColor(foreground, accent), focusFillAlpha) }
  function selectionFillFor(foreground, accent) { return Util.alpha(selectionStateColor(foreground, accent), selectionFillAlpha) }

  function normalBorderFor(foreground, accent) { return Util.alpha(normalStateColor(foreground, accent), normalBorderAlpha) }
  function hoverBorderFor(foreground, accent) { return Util.alpha(hoverStateColor(foreground, accent), hoverBorderAlpha) }
  function selectedBorderFor(foreground, accent) { return Util.alpha(selectedStateColor(foreground, accent), selectedBorderAlpha) }
  function focusBorderFor(foreground, accent) { return Util.alpha(focusStateColor(foreground, accent), focusBorderAlpha) }

  // Focus, then hover, then normal: the order every form control paints in.
  function controlFill(focused, hot, foreground, accent) {
    if (focused) return focusFillFor(foreground, accent)
    if (hot) return hoverFillFor(foreground, accent)
    return normalFillFor(foreground, accent)
  }

  readonly property QtObject spacing: QtObject {
    readonly property int hairline: root.space(1)
    readonly property int xxs: root.space(2)
    readonly property int xs: root.space(3)
    readonly property int sm: root.space(4)
    readonly property int md: root.space(6)
    readonly property int lg: root.space(8)
    readonly property int xl: root.space(10)
    readonly property int xxl: root.space(12)
    readonly property int xxxl: root.space(14)
    readonly property int huge: root.space(18)

    readonly property int controlGap: root.space(8)
    readonly property int controlPaddingX: root.space(10)
    readonly property int controlPaddingY: root.space(6)
    readonly property int inputPaddingY: root.space(7)
    readonly property int controlHeight: root.space(28)
    readonly property int popupRowHeight: root.space(28)
    readonly property int rowGap: root.space(8)
    readonly property int rowPaddingX: root.space(12)
    readonly property int labelGap: root.space(4)
    readonly property int panelGap: root.space(14)
    readonly property int panelPadding: root.space(18)
    readonly property int popupPadding: root.space(14)
  }

  function fontPx(mult) {
    return Math.max(1, Math.round(fontSize * mult))
  }

  readonly property QtObject font: QtObject {
    readonly property string family: root.fontFamily
    readonly property int baseSize: root.fontSize

    readonly property int caption: root.fontPx(0.833)
    readonly property int bodySmall: root.fontPx(0.917)
    readonly property int body: root.fontPx(1.0)
    readonly property int subtitle: root.fontPx(1.083)
    readonly property int title: root.fontPx(1.167)
    readonly property int heading: root.fontPx(1.333)
    readonly property int display: root.fontPx(2.0)
    readonly property int displayLarge: root.fontPx(2.333)

    readonly property int iconSmall: bodySmall
    readonly property int icon: title
    readonly property int iconLarge: root.fontPx(1.5)
  }
}
