import QtQuick
import qs.ui

// Empty space between widgets; `size` is its length in pixels (default 12).
BarWidget {
  id: root

  readonly property int span: Math.round(Number(setting("size", 12)))

  implicitWidth: vertical ? barSize : span
  implicitHeight: vertical ? span : barSize
  visible: span > 0
}
