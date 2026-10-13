# mido

A minimal Quickshell shell, ported from the Omarchy "quattro" bar. No plugin
system and no theme manager: colors come from matugen, layout from `settings.json`.

## Install (Fedora)

One command: installs SDDM, Hyprland, Quickshell (from its COPR) and all
dependencies, puts the config in `~/.config/mido` and wires up the `mido`
commands:

    curl -fsSL https://raw.githubusercontent.com/corzyy/mido/main/install.sh | bash

Or from a checkout:

    git clone https://github.com/corzyy/mido ~/.config/mido
    ~/.config/mido/install.sh

The installer is safe to re-run. Afterwards log out and pick the Hyprland
session in SDDM (mido starts with it), or start it inside a running Hyprland
session with `mido start`.

```
shell.qml            entry point, instantiates the modules
bin/mido             the `mido` control command
settings.json        user settings, hot-reloaded (merged over core/Config.qml defaults)
core/                singletons: Config, Colors (matugen palette), Style, Util
ui/                  shared building blocks: BarWidget (base), WidgetButton, BarIconButton, OpticalGlyph
modules/bar/         the bar (windows, sections, drag and drop), BarModel.js, the widget registry
widgets/             one file per bar widget
assets/              the Omarchy logo font
matugen/             matugen template for the palette
generated/           matugen output (git-ignored)
```

Control it with the `mido` command (`bin/mido`, symlinked into `~/.local/bin`):
`mido start | stop | restart | status | log [-f] | ipc ... | run | edit`.
It only ever targets this config, never other Quickshell instances.

## Theming (matugen)

Add to `~/.config/matugen/config.toml`:

```toml
[templates.mido]
input_path  = '~/.config/mido/matugen/colors.json'
output_path = '~/.config/mido/generated/colors.json'
```

`core/Colors.qml` watches the output and updates live, no post-hook needed.
Mapping: `surface` → background, `on_surface` → foreground, `primary` → accent,
`error` → urgent, `outline` → muted. Edit `Colors.apply()` to change it.

## Bar gestures

Same as Omarchy. Every change is written to `settings.json` (`bar.layout`,
`bar.position`, `bar.background`), so it survives a restart.

- Drag a widget to reorder it or move it to another section.
- Drag, or click and hold, empty bar space toward a screen edge to move the bar there.
- Double-click empty bar space to cycle the background: clear, glassy, opaque.
- Glassy only blurs if Hyprland is told to: add a layer rule with blur for namespace `mido-bar`.

Scriptable twins: `mido ipc call bar move <id> <left|center|right> [beforeId]`,
`... bar position <top|bottom|left|right>`, `... bar background <opaque|glassy|none|cycle>`.

## Bar layout

`settings.json` → `bar.layout.{left,center,right}` is a list of `{ "id": ... }`
entries; every other key is passed to the widget as a setting. `position` is
`top`, `bottom`, `left` or `right`; `background` is `opaque`, `glassy` or `none`;
`centerAnchor` names the center widget pinned to the exact middle of the screen.
An `omarchy.` prefix on an id is ignored.

| id              | settings                              |
|-----------------|---------------------------------------|
| `menu`          | `onClick`, `onRightClick` (commands)  |
| `workspaces`    |                                       |
| `active-window` | `maxWidth`                            |
| `clock`         | `format`, `formatAlt` (right click toggles), `verticalFormat` |
| `tray`          |                                       |
| `audio`         | `step`, `onRightClick` (command)      |
| `battery`       | `low` (urgent threshold, %), `showPercentage` (right click toggles) |

## Adding things

**A bar widget**: create `widgets/Foo.qml` extending `BarWidget` (see `Clock.qml`
for the smallest example), then add `"foo": "Foo"` to
`modules/bar/WidgetRegistry.qml`. Use it in `settings.json` as `{ "id": "foo" }`.

**A whole feature** (launcher, OSD, notifications, lock): create
`modules/<name>/` with a `qmldir` and a root component, then instantiate it in
`shell.qml`. Give it settings by adding a default section to `core/Config.qml`.

## Differences from Omarchy

Dropped: plugin manifests/registry, theme/`shell.toml` integration, Omarchy
commands (layout toggle, update indicator), the tray's drawer (so widgets can't be
dragged into it), popup panels (calendar, network, bluetooth, ...), display
notch handling, hiding the bar, and the other overlays. Those are the
natural next modules.
