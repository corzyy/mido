pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// User settings from settings.json (next to shell.qml), hot-reloaded on save.
// Top-level sections are merged one level deep over the defaults below, so a
// settings.json only needs the keys it changes. Add a section for a new module
// by giving it a default here and reading it as `Config.<section>`.
//
// The bar edits its own settings: dragging widgets, moving the bar to another
// edge and cycling its background all go through mutate(), which writes the
// result back to settings.json. Once written, the file is canonical (the
// layout is replaced, not merged), exactly as in Omarchy's shell.json.
Singleton {
  id: root

  readonly property var defaults: ({
    shell: {
      // Name of the one screen everything renders on (e.g. "DP-1"); empty for all.
      screen: "",
      // Terminal for things that run a command in a window, started as `<terminal> -e ...`.
      terminal: "kitty"
    },
    bar: {
      position: "top",
      background: "opaque",
      centerAnchor: "clock",
      height: 26,
      font: "monospace",
      fontSize: 12,
      layout: {
        left: [{ id: "menu" }, { id: "workspaces" }],
        center: [{ id: "clock", format: "dddd HH:mm", formatAlt: "d MMMM 'W'ww yyyy" }],
        right: [{ id: "tray" }, { id: "audio" }, { id: "battery" }]
      }
    }
  })

  property var data: defaults
  // What is on disk, unmerged. mutate() edits a copy of this.
  property var user: ({})

  readonly property var bar: data.bar
  readonly property var shell: data.shell

  // The screens the shell renders on: just `shell.screen`, or all of them when
  // it is empty or not connected, so an unplugged monitor never leaves no bar.
  readonly property var screens: {
    var all = Quickshell.screens
    var name = String(shell.screen || "")
    if (name === "") return all
    var match = all.filter(function(screen) { return screen.name === name })
    return match.length > 0 ? match : all
  }

  function merge(user) {
    var out = {}
    for (var section in defaults)
      out[section] = Object.assign({}, defaults[section], user && user[section] ? user[section] : {})
    return out
  }

  function clone(value) {
    return JSON.parse(JSON.stringify(value))
  }

  // Edit the settings and persist them. `change` receives a mutable copy of the
  // file's contents with bar.layout filled in from what is currently shown, so
  // the first drag on a default layout saves the whole layout. Return false
  // from `change` to leave everything as it was.
  function mutate(change) {
    var next = clone(user && typeof user === "object" ? user : {})
    if (!next.bar || typeof next.bar !== "object") next.bar = {}
    if (!next.bar.layout) next.bar.layout = clone(data.bar.layout)
    if (change(next) === false) return false
    user = next
    data = merge(next)
    file.setText(JSON.stringify(next, null, 2) + "\n")
    return true
  }

  // Replace the settings entry of the bar widget `id` with `entry` and persist it.
  function updateEntry(id, entry) {
    return mutate(function(config) {
      var layout = config.bar.layout
      for (var region in layout) {
        var list = layout[region]
        for (var i = 0; i < list.length; i++) {
          if (list[i] && list[i].id === id) {
            list[i] = entry
            return true
          }
        }
      }
      return false
    })
  }

  FileView {
    id: file
    path: Quickshell.shellPath("settings.json")
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        // Our own write comes back through the watcher; nothing to do then.
        if (JSON.stringify(parsed) === JSON.stringify(root.user)) return
        root.user = parsed
        root.data = root.merge(parsed)
      } catch (e) {
        console.warn("settings.json: " + e)
      }
    }
    onLoadFailed: {
      root.user = ({})
      root.data = root.defaults
    }
  }
}
