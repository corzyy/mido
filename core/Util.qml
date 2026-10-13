pragma Singleton
import QtQuick
import Quickshell

Singleton {
  function clamp(value, low, high) {
    return Math.max(low, Math.min(high, value))
  }

  // Fire-and-forget command, no shell involved.
  function run(argv) {
    Quickshell.execDetached(argv)
  }

  // Fire-and-forget shell command line.
  function runShell(command) {
    if (command) Quickshell.execDetached(["bash", "-lc", String(command)])
  }

  // A color with its alpha replaced by `opacity` (0 to 1).
  function alpha(color, opacity) {
    var c = Qt.color(color)
    return Qt.rgba(c.r, c.g, c.b, clamp(opacity, 0, 1))
  }

  // A string as one shell word.
  function shellQuote(text) { return quote(text) }

  function quote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'"
  }

  // A command line that runs `command` in the configured terminal; `wait` keeps the
  // window open until a key is pressed.
  function terminalCommand(command, wait) {
    var inner = wait ? command + '; echo; read -n 1 -s -r -p "Press any key to close"' : command
    return Config.shell.terminal + " -e bash -lc " + quote(inner)
  }

  // A glyph by code point; QML string escapes only reach the BMP.
  function glyph(codePoint) {
    return String.fromCodePoint(codePoint)
  }

  function isPlainObject(value) {
    return !!value && typeof value === "object" && !Array.isArray(value)
  }

  // One wheel notch is 120 units; touchpads send smaller deltas that add up.
  // Returns { steps, remainder }; feed the remainder back in on the next event.
  function wheelSteps(accumulator, delta) {
    delta = clamp(delta, -120, 120)
    if (accumulator * delta < 0) accumulator = 0
    var total = accumulator + delta
    var steps = total < 0 ? Math.ceil(total / 120) : Math.floor(total / 120)
    return { steps: steps, remainder: total - steps * 120 }
  }
}
