import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.core
import "MenuModel.js" as MenuModel

// The main menu: a small centered list with a filter field, opened with
// `mido ipc call menu toggle` (Super+Space). Enter opens a submenu or runs the
// entry, Escape goes up one level and closes at the top, typing filters.
// The tree lives in MenuModel.js.
Scope {
  id: root

  property bool shown: false
  property var rootNode: MenuModel.tree()
  // The submenus entered so far, starting with the root.
  property var stack: [rootNode]
  property string query: ""
  property int index: 0
  property var installed: ({})

  readonly property var current: stack[stack.length - 1]
  readonly property var entries: collect(current, query.trim().toLowerCase(), installed, DesktopEntries.applications.values)

  function collect(node, needle, have, apps) {
    var source = []
    if (node.apps) {
      for (var i = 0; i < apps.length; i++) {
        var app = apps[i]
        if (app.noDisplay) continue
        source.push({ label: app.name, appIcon: Quickshell.iconPath(app.icon, true) || Quickshell.iconPath("application-x-executable", true), app: app })
      }
      source.sort(function(a, b) { return a.label.localeCompare(b.label) })
    } else {
      source = (node.items || []).filter(function(item) { return !item.needs || have[item.needs] === true })
    }

    var ranked = []
    for (var j = 0; j < source.length; j++) {
      var rank = MenuModel.score(source[j].label, needle)
      if (rank > 0) ranked.push({ item: source[j], rank: rank, order: j })
    }
    if (needle !== "")
      ranked.sort(function(a, b) { return b.rank - a.rank || a.order - b.order })
    return ranked.map(function(r) { return r.item })
  }

  function open(path) {
    var nodes = MenuModel.resolve(rootNode, path)
    stack = nodes || [rootNode]
    query = ""
    index = 0
    shown = true
  }

  function close() {
    shown = false
  }

  function toggle() {
    if (shown) close()
    else open("")
  }

  function enter(node) {
    stack = stack.concat([node])
    query = ""
    index = 0
  }

  function back() {
    if (stack.length <= 1) {
      close()
      return
    }
    stack = stack.slice(0, -1)
    query = ""
    index = 0
  }

  function activate(item) {
    if (!item) return
    if (item.items || item.apps) {
      enter(item)
      return
    }
    close()
    if (item.app) item.app.execute()
    else if (item.run) Util.runShell(item.run)
    else if (item.term) Util.runShell(Util.terminalCommand(item.term, true))
    else if (item.tui) Util.runShell(Util.terminalCommand(item.tui, false))
  }

  // Which of the executables the tree needs are installed.
  Process {
    running: true
    command: ["bash", "-c", 'for b in "$@"; do command -v "$b" >/dev/null && echo "$b"; done', "_"].concat(MenuModel.needs(root.rootNode))
    stdout: SplitParser {
      onRead: function(line) {
        var next = Object.assign({}, root.installed)
        next[line] = true
        root.installed = next
      }
    }
  }

  IpcHandler {
    target: "menu"

    function toggle(): void { root.toggle() }
    function open(path: string): void { root.open(path) }
    function close(): void { root.close() }
  }

  PanelWindow {
    id: window

    visible: root.shown
    screen: Config.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "mido-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: if (visible) field.forceActiveFocus()

    MouseArea {
      anchors.fill: parent
      onClicked: root.close()
    }

    Rectangle {
      id: box

      readonly property int rowHeight: Style.token(50)
      readonly property int headerHeight: Style.token(34)
      readonly property int rowSpacing: Style.token(3)
      readonly property int contentSpacing: Style.token(6)
      readonly property int padding: Style.token(18)
      readonly property int maxListHeight: Math.round(window.height * 0.7)

      anchors.centerIn: parent
      width: Style.token(300)
      height: padding * 2 + field.height + contentSpacing + list.height
      color: Colors.background
      border.color: Colors.accent
      border.width: 2
      radius: Style.cornerRadius

      MouseArea { anchors.fill: parent }

      TextInput {
        id: field

        x: box.padding
        y: box.padding
        width: parent.width - box.padding * 2
        height: box.headerHeight
        verticalAlignment: TextInput.AlignVCenter
        color: Colors.foreground
        selectionColor: Colors.accent
        selectedTextColor: Colors.background
        font.family: Style.fontFamily
        font.pixelSize: Style.token(16)
        clip: true
        text: root.query
        onTextChanged: {
          root.query = text
          root.index = 0
        }

        Text {
          visible: field.text === ""
          anchors.verticalCenter: parent.verticalCenter
          color: Colors.muted
          font: field.font
          text: root.current.label + "…"
        }

        Keys.onPressed: function(event) {
          var ctrl = (event.modifiers & Qt.ControlModifier) !== 0
          var count = root.entries.length
          if (event.key === Qt.Key_Escape) root.back()
          else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_N || event.key === Qt.Key_J)))
            root.index = count > 0 ? (root.index + 1) % count : 0
          else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_P || event.key === Qt.Key_K)))
            root.index = count > 0 ? (root.index - 1 + count) % count : 0
          else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activate(root.entries[root.index])
          else return
          event.accepted = true
        }
      }

      ListView {
        id: list

        x: box.padding
        y: box.padding + field.height + box.contentSpacing
        width: parent.width - box.padding * 2
        height: Math.min(Math.max(0, count * (box.rowHeight + box.rowSpacing) - box.rowSpacing), box.maxListHeight)
        spacing: box.rowSpacing
        model: root.entries
        currentIndex: root.index
        clip: true
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        delegate: Item {
          id: row

          required property var modelData
          required property int index
          readonly property bool selected: index === root.index

          width: list.width
          height: box.rowHeight

          Rectangle {
            anchors.fill: parent
            color: Colors.foreground
            opacity: row.selected ? 0.1 : 0
          }

          Item {
            id: iconSlot

            x: Style.token(8)
            width: Style.token(36)
            height: parent.height

            Text {
              visible: !row.modelData.appIcon
              anchors.centerIn: parent
              color: row.selected ? Colors.accent : Colors.foreground
              font.family: Style.fontFamily
              font.pixelSize: Style.token(18)
              text: row.modelData.icon || ""
            }

            Image {
              visible: !!row.modelData.appIcon
              anchors.centerIn: parent
              width: Style.token(18)
              height: width
              sourceSize: Qt.size(width, width)
              source: row.modelData.appIcon || ""
            }
          }

          Text {
            anchors.left: iconSlot.right
            anchors.leftMargin: Style.token(6)
            anchors.right: parent.right
            anchors.rightMargin: Style.token(6)
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            color: row.selected ? Colors.accent : Colors.foreground
            font.family: Style.fontFamily
            font.pixelSize: Style.token(16)
            font.weight: Font.Medium
            text: row.modelData.label
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: root.index = row.index
            onClicked: root.activate(row.modelData)
          }
        }
      }
    }
  }
}
