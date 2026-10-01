# Hover Screens

Hover Screens is a KDE Plasma 6 widget that provides live miniature views of
windows across physical monitors and virtual desktops.

It has two primary views:

- **Overview** — shows the current virtual desktop of each physical output.
- **Grid View** — browses virtual desktops, grouped either by desktop or by
  physical screen.

Hover Screens is designed for Plasma/Wayland and uses Plasma TaskManager and
PipeWire for previews. Exact per-output virtual-desktop switching is handled by
a small bundled KWin JavaScript companion.

## Screenshots

| | |
| --- | --- |
| ![Hover Screens screenshot 1](screenshots/1.jpeg) | ![Hover Screens screenshot 2](screenshots/2.jpeg) |
| ![Hover Screens screenshot 3](screenshots/3.jpeg) | ![Hover Screens screenshot 4](screenshots/4.jpeg) |

## Requirements

- KDE Plasma **6.4+**
- KWin / Wayland
- Plasma TaskManager QML module
- KDE PipeWire QML module

Developed and live-tested on Plasma 6.7.x.

## Features

### Overview

Window layouts:

- **Natural** — aspect-aware non-overlapping packing; default.
- **Reflow** — balanced grid packing.
- **Horizontal** — one row.
- **Vertical** — one column.
- **Spatial** — preserves real window positions and physical monitor topology.
- **Adaptive** — chooses an appropriate packed layout from available geometry.

Screen arrangement:

- **Fill topology** — fills the available widget area; non-Spatial monitor cards
  may stretch with the available geometry.
- **Adaptive** — preserves each monitor card's physical aspect ratio and repacks
  screens according to the available widget shape.

Adaptive screen arrangement fits rows independently, so portrait screens can
remain large while a wide landscape row uses a shorter height when appropriate.
Spatial always keeps the real physical monitor topology.

Each physical screen has its own virtual-desktop control. At normal sizes the
desktop strip stays outside the window surface; at cramped heights it becomes a
small non-interactive active-desktop indicator so previews keep the available
space.

Desktop controls:

- click a desktop chip → switch that exact physical output
- vertical wheel over a strip or screen pane → previous/next desktop
- Shift+wheel or horizontal wheel over an overflowing strip → pan the strip
- optional wrapping at the first/last desktop

### Grid View

Grid uses the same per-screen renderer as Overview.

Window layouts:

- Natural
- Reflow
- Horizontal
- Vertical
- Spatial
- Adaptive

Grouping:

- **By desktop** — each virtual desktop contains its physical-screen previews.
- **By screen** — each physical screen contains that screen's virtual desktops.

Desktop arrangement:

- **Follow KDE layout** — respects KDE's configured desktop row layout.
- **Adaptive** — presentation-only packing chosen from available geometry.

By-screen desktop miniatures preserve the physical monitor aspect ratio and stay
tightly grouped. Screen groups follow physical virtual-desktop position.

Clicking an empty screen/desktop miniature changes only that exact physical
output to that desktop. Window previews keep their normal window activation.

### Live previews

Live preview modes:

- **On hover**
- **Always**
- **Off**

On-hover start and stop delays are configurable. Preview capture is
lifetime-gated rather than polled continuously.

## Architecture

Overview and Grid share one per-screen renderer:

```text
OverviewScreen                         GridScreenSurface
     │                                        │
     └──────────────┐          ┌──────────────┘
                    ▼          ▼
                 ScreenLayoutSurface
                    │
            ┌───────┴────────┐
            ▼                ▼
 OverviewWindowLayout   ScreenSpatialWindow
```

`ScreenLayoutSurface.qml` is the authoritative per-screen layout renderer.
Overview and Grid differ primarily in how their TaskManager models are filtered
and how navigation is presented.

The KWin companion has a deliberately narrow responsibility:

- set one output to one numbered virtual desktop
- step one output to the previous/next desktop
- publish exact per-output desktop state through KGlobalAccel's existing D-Bus
  shortcut signal

It does **not** poll, run shell commands, expose arbitrary JavaScript, or
manipulate windows.

## Installation

Download the plasmoid and companion from the release assets.

### Arch Linux / CachyOS package

The release also includes a system package containing both the plasmoid and the
KWin companion:

```fish
sudo pacman -U ./plasma6-applets-hover-screens-1.0.0-1-any.pkg.tar.zst

kwriteconfig6 \
    --file kwinrc \
    --group Plugins \
    --key io.github.suppdiff.hoverscreens.companionEnabled \
    true

qdbus6 org.kde.KWin /KWin reconfigure
qdbus6 org.kde.KWin /Scripting start
systemctl --user restart plasma-plasmashell.service
```

### Plasmoid

Fresh install:

```fish
kpackagetool6 -t Plasma/Applet -i ./Hover_Screens-<version>.plasmoid
systemctl --user restart plasma-plasmashell.service
```

Update an existing installation:

```fish
kpackagetool6 -t Plasma/Applet -u ./Hover_Screens-<version>.plasmoid
systemctl --user restart plasma-plasmashell.service
```

### KWin companion

Install the companion once for exact per-output desktop switching:

```fish
kpackagetool6 -t KWin/Script -i ./Hover_Screens-Companion-1.0.0.kwinscript

kwriteconfig6 \
    --file kwinrc \
    --group Plugins \
    --key io.github.suppdiff.hoverscreens.companionEnabled \
    true

qdbus6 org.kde.KWin /KWin reconfigure
qdbus6 org.kde.KWin /Scripting start
```

To update an already-installed companion, use `-u` instead of `-i`.

The companion does not need reinstalling when only the plasmoid changes and the
companion version remains the same.

## Security notes

- no shell execution from QML or the KWin companion
- no polling daemon
- no cookie, session, or token access
- per-output desktop actions use a defined KGlobalAccel naming scheme
- only normalized native action names are accepted by the plasmoid

## License

Hover Screens is licensed under **GPL-3.0-or-later**.

See [LICENSE](LICENSE) for the full GNU General Public License version 3 text.
