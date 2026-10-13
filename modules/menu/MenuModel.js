.pragma library

// The menu tree. A node is one of:
//   { label, icon, items: [...] }   a submenu
//   { label, icon, apps: true }     a submenu listing the installed applications
//   { label, icon, run: "cmd" }     a shell command line, run detached
//   { label, icon, term: "cmd" }    run in a terminal, which waits for a key afterwards
//   { label, icon, tui: "cmd" }     run in a terminal that closes when the command ends
// `needs` names an executable; the entry is hidden while it is not installed.
// Icons are Font Awesome code points from the Nerd Font.

var HOME = '"$HOME"'

function edit(path) {
  return '${EDITOR:-nvim} ' + HOME + '/' + path
}

function tree() {
  return {
    label: "Go",
    items: [
      { label: "Apps", icon: "", apps: true },

      { label: "Learn", icon: "", items: [
        { label: "Keybindings", icon: "", term: "hyprctl binds | less" },
        { label: "Hyprland", icon: "", run: "xdg-open https://wiki.hypr.land/" },
        { label: "Fedora", icon: "", run: "xdg-open https://docs.fedoraproject.org/" },
        { label: "Bash", icon: "", run: "xdg-open https://www.gnu.org/software/bash/manual/" },
        { label: "Neovim", icon: "", run: "xdg-open https://neovim.io/doc/" }
      ] },

      { label: "Trigger", icon: "", items: [
        { label: "Capture", icon: "", items: [
          { label: "Screenshot", icon: "", items: [
            { label: "Region", icon: "", needs: "hyprshot", run: 'hyprshot -m region -o "$(xdg-user-dir PICTURES)/Screenshots"' },
            { label: "Window", icon: "", needs: "hyprshot", run: 'hyprshot -m window -o "$(xdg-user-dir PICTURES)/Screenshots"' },
            { label: "Display", icon: "", needs: "hyprshot", run: 'hyprshot -m output -o "$(xdg-user-dir PICTURES)/Screenshots"' }
          ] },
          { label: "Screenrecording", icon: "", needs: "gpu-screen-recorder",
            run: 'if pgrep -x gpu-screen-recorder >/dev/null; then pkill -SIGINT -x gpu-screen-recorder; notify-send "Screenrecording saved"; '
               + 'else notify-send "Screenrecording started"; gpu-screen-recorder -w portal -f 60 -a default_output -o "$(xdg-user-dir VIDEOS)"; fi' },
          { label: "Color", icon: "", needs: "hyprpicker", run: "hyprpicker -a" }
        ] },
        { label: "Toggle", icon: "", items: [
          { label: "Top Bar Background", icon: "", run: "mido ipc call bar background cycle" }
        ] }
      ] },

      { label: "Style", icon: "", items: [
        { label: "Hyprland", icon: "", tui: edit(".config/hypr/configs/appearance.lua") },
        { label: "Theme", icon: "", tui: edit(".config/hypr/configs/theme.lua") },
        { label: "Bar", icon: "", tui: edit(".config/mido/settings.json") }
      ] },

      { label: "Setup", icon: "", items: [
        { label: "Audio", icon: "", needs: "wiremix", tui: "wiremix" },
        { label: "Wifi", icon: "", needs: "impala", tui: "impala" },
        { label: "Bluetooth", icon: "", needs: "bluetui", tui: "bluetui" },
        { label: "Power Profile", icon: "", needs: "powerprofilesctl", items: [
          { label: "Power Saver", icon: "", run: "powerprofilesctl set power-saver" },
          { label: "Balanced", icon: "", run: "powerprofilesctl set balanced" },
          { label: "Performance", icon: "", run: "powerprofilesctl set performance" }
        ] },
        { label: "Monitors", icon: "", tui: edit(".config/hypr/configs/monitors.lua") },
        { label: "Keybindings", icon: "", tui: edit(".config/hypr/configs/binds.lua") },
        { label: "Input", icon: "", tui: edit(".config/hypr/configs/input.lua") },
        { label: "Config", icon: "", items: [
          { label: "Hyprland", icon: "", tui: edit(".config/hypr/hyprland.lua") },
          { label: "Autostart", icon: "", tui: edit(".config/hypr/configs/autostart.lua") },
          { label: "Windows", icon: "", tui: edit(".config/hypr/configs/windows.lua") },
          { label: "Bar", icon: "", tui: edit(".config/mido/settings.json") }
        ] }
      ] },

      { label: "Install", icon: "", items: [
        { label: "Package", icon: "", term: 'read -rp "Install package: " p && [ -n "$p" ] && sudo dnf install $p' },
        { label: "Flatpak", icon: "", needs: "flatpak", term: 'read -rp "Install flatpak: " p && [ -n "$p" ] && flatpak install $p' }
      ] },

      { label: "Remove", icon: "", items: [
        { label: "Package", icon: "", term: 'read -rp "Remove package: " p && [ -n "$p" ] && sudo dnf remove $p' },
        { label: "Flatpak", icon: "", needs: "flatpak", term: 'read -rp "Remove flatpak: " p && [ -n "$p" ] && flatpak uninstall $p' }
      ] },

      { label: "Update", icon: "", items: [
        { label: "System", icon: "", term: "sudo dnf upgrade" },
        { label: "Firmware", icon: "", needs: "fwupdmgr", term: "fwupdmgr refresh && fwupdmgr update" },
        { label: "Process", icon: "", items: [
          { label: "Shell", icon: "", run: "mido restart" }
        ] }
      ] },

      { label: "About", icon: "", needs: "fastfetch", term: "fastfetch" },

      { label: "System", icon: "", items: [
        { label: "Lock", icon: "", run: "loginctl lock-session" },
        { label: "Suspend", icon: "", run: "systemctl suspend" },
        { label: "Hibernate", icon: "", run: "systemctl hibernate" },
        { label: "Logout", icon: "", run: 'loginctl terminate-session "$XDG_SESSION_ID"' },
        { label: "Restart", icon: "", run: "systemctl reboot" },
        { label: "Shutdown", icon: "", run: "systemctl poweroff" }
      ] }
    ]
  }
}

// Every executable named by a `needs`, once each.
function needs(node, out) {
  out = out || []
  if (node.needs && out.indexOf(node.needs) === -1) out.push(node.needs)
  var items = node.items || []
  for (var i = 0; i < items.length; i++) needs(items[i], out)
  return out
}

// Resolve "trigger/capture" to the submenu nodes leading there, or null.
function resolve(root, path) {
  var nodes = [root]
  var parts = String(path || "").split("/").filter(function(p) { return p !== "" })
  for (var i = 0; i < parts.length; i++) {
    var items = nodes[nodes.length - 1].items || []
    var want = parts[i].toLowerCase()
    var hit = null
    for (var j = 0; j < items.length; j++) {
      if (items[j].label.toLowerCase() === want && (items[j].items || items[j].apps)) { hit = items[j]; break }
    }
    if (!hit) return null
    nodes.push(hit)
  }
  return nodes
}

// Rank a label against a query: 0 = no match, higher is better.
function score(label, query) {
  if (query === "") return 1
  var text = label.toLowerCase()
  if (text.indexOf(query) === 0) return 4
  if (text.indexOf(" " + query) !== -1) return 3
  if (text.indexOf(query) !== -1) return 2
  var at = 0
  for (var i = 0; i < query.length; i++) {
    at = text.indexOf(query[i], at)
    if (at === -1) return 0
    at++
  }
  return 1
}
