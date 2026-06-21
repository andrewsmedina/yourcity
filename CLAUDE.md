# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

TaskbarCity — an idle/city-builder game that runs in a thin window docked to the
screen edge (taskbar-style). The city runs itself while the player works; the
player intervenes both proactively (building/upgrading zones) and reactively
(resolving crises). Target engine is **Godot 4**, shipping for **Windows, Linux
and macOS**.

**Status: pre-code.** As of this writing the repo contains only the design doc —
no Godot project exists yet. The Foundation tasks (see Issues) are the first code
to be written.

## Source of truth

- **`docs/GDD_TaskbarCity.md`** is the canonical design. Read it before making any
  gameplay/systems decision — it defines the economy, the 5 indicators
  (Segurança, Educação, Saúde, Tráfego, **Energia**) plus derived Felicidade, the
  crisis system, the per-OS window strategy, and provisional balancing numbers.
- Work is tracked in **GitHub Issues** under **milestone `0.1`** (repo
  `andrewsmedina/yourcity`), one issue per task. The local `.jsx` tracker that
  used to hold this was removed once issues took over — do not recreate it.

## Issue conventions

Issues carry an area label (`foundation`, `visual`, `economy`, `indicators`,
`crises`, `ui`, `progression`, `beta`) and may carry a **flow** label:

- **`critical-path`** — blocks other work; do early. Currently the Foundation
  issues (Godot window docked per-OS). The macOS window is the highest technical
  risk: there is no taskbar, so it's a borderless window anchored above the Dock
  plus a menu-bar icon, with Spaces/permissions handled explicitly.
- **`parallel`** — pure simulation logic (economy, indicators, crises) with no
  dependency on the window or art; can be built and tested in isolation, in any
  order.

Priority for now = issue creation order (#1 Foundation → … → Beta), with
`critical-path`/`parallel` labels as the tie-breaker when ordering conflicts. The
creation order intentionally front-loads Foundation, but note Visual (#9–12) was
created before the simulation core (#13–31) even though the simulation is the more
foundational work — prefer the simulation core over art when choosing what to do
next.

## Architecture (planned)

Keep the **simulation core decoupled from the view**. The economy, indicators and
crisis systems are deterministic logic that must run and be testable without any
window or sprite. The Godot window/UI is a thin presentation layer that reads
simulation state (money, the 5 indicators, Felicidade) and renders bars, toasts
and the decision panel. This separation is what makes the `parallel` issues
buildable before the `critical-path` window work is finished.

## Build / test commands

Godot 4.6 project at the repo root (`project.godot`).

- **Import assets** (run after adding/changing assets, and on fresh checkout):
  `godot --headless --import`
- **Boot the game headless** (smoke check, prints the boot line then exits):
  `godot --headless --quit-after 5`
- **Run the simulation tests:** `godot --headless --script tests/run_tests.gd`
  — exits non-zero on failure. Add new pure-sim checks to `tests/run_tests.gd`.
- **Regenerate placeholder art:** `python3 tools/gen_placeholder_spritesheet.py`

Headless has no real display: window docking, the tray/menu-bar icon and the
rendered skyline/day-night cannot be verified this way — only that code loads and
runs without errors. Verify those visually by opening the project in the Godot
editor.

## Code map

- `scripts/sim/` — **pure simulation** (`CitySim`, `class_name`, extends
  RefCounted). No engine/scene deps; unit-tested directly in `tests/`.
- `scripts/city.gd` — `City` autoload: ticks the sim and emits signals for the UI.
- `scripts/window_manager.gd` — `WindowManager` autoload: borderless,
  always-on-top, per-OS docking, idle/expanded resize.
- `scripts/tray_icon.gd` — `TrayIcon` autoload: macOS menu-bar / Windows tray.
- `scripts/city_tiles.gd` — `CityTiles` autoload: slices the spritesheet by name.
- `scripts/skyline.gd`, `scripts/day_night.gd` — view layer (scene nodes).
