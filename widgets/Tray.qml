import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.core
import qs.ui

// StatusNotifier tray icons. Click activates, middle-click secondary-activates,
// right-click opens the item's menu.
BarWidget {
  id: root

  implicitWidth: vertical ? barSize : layout.implicitWidth
  implicitHeight: vertical ? layout.implicitHeight : barSize
  visible: SystemTray.items.values.length > 0

  Grid {
    id: layout
    anchors.centerIn: parent
    columns: root.vertical ? 1 : SystemTray.items.values.length
    rows: root.vertical ? SystemTray.items.values.length : 1

    Repeater {
      model: SystemTray.items

      delegate: MouseArea {
        id: entry
        required property SystemTrayItem modelData

        width: Style.bar.iconSlot
        height: Style.bar.iconSlot
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        visible: modelData.status !== Status.Passive

        onEntered: if (root.bar) root.bar.showTooltip(entry, modelData.tooltipTitle || modelData.title || modelData.id || "")
        onExited: if (root.bar) root.bar.hideTooltip(entry)
        readonly property bool tooltipHovered: visible && containsMouse

        onClicked: function(mouse) {
          if (root.bar) root.bar.hideTooltip(entry)
          if (mouse.button === Qt.MiddleButton) {
            modelData.secondaryActivate()
          } else if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
            if (!modelData.hasMenu) return
            var point = entry.mapToItem(null, 0, height)
            modelData.display(entry.QsWindow.window, point.x, point.y)
          } else {
            modelData.activate()
          }
        }

        Image {
          x: (parent.width - width) / 2
          y: (parent.height - height) / 2
          width: Style.bar.iconSize
          height: Style.bar.iconSize
          fillMode: Image.PreserveAspectFit
          sourceSize.width: Math.round(width * Screen.devicePixelRatio)
          sourceSize.height: Math.round(height * Screen.devicePixelRatio)
          source: entry.modelData.icon
        }
      }
    }
  }
}
