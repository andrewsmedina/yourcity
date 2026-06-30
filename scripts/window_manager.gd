extends Node

## Centralizes all window tweaks for the taskbar layout.
##
## Owns the window's appearance and placement so the rest of the game never
## touches DisplayServer directly:
##   - borderless + always-on-top (issues #2, #3)
##   - docking full-width to the bottom edge of the active screen (issues #4-#6)
##   - idle <-> expanded resize, growing upward from that edge (issue #8)
##
## Per-OS docking is handled by a single shared path: screen_get_usable_rect()
## already excludes the Windows taskbar, the macOS Dock/menu bar, and Linux WM
## panels/struts, so pinning to the usable rect's bottom edge Just Works on all
## three. (The macOS menu-bar status icon lives in issue #7.)

const HEIGHT_IDLE := 800  # GRID_TOP(80) + GRID_ROWS(15) * TILE(48)
const HEIGHT_EXPANDED := 980
const MIN_SIZE := Vector2i(1280, 800)

var _expanded := false

func _ready() -> void:
	get_window().min_size = MIN_SIZE
	apply_mode()

## Apply the current window mode: normal movable window (default) or the docked
## always-on-top taskbar bar.
func apply_mode() -> void:
	var window := get_window()
	if Settings.taskbar_mode:
		window.borderless = true
		window.always_on_top = true
		redock()
	else:
		window.borderless = false
		window.always_on_top = false
		_center_normal_window()

## Toggle between normal and taskbar modes (T key) and remember the choice.
func toggle_mode() -> void:
	Settings.taskbar_mode = not Settings.taskbar_mode
	Settings.save_settings()
	apply_mode()

func _center_normal_window() -> void:
	var window := get_window()
	var rect := DisplayServer.screen_get_usable_rect(window.current_screen)
	if rect.size.x <= 0:
		return
	window.size = Vector2i(mini(rect.size.x - 80, 2800), HEIGHT_IDLE)
	window.position = rect.position + (rect.size - window.size) / 2

## Pin the window full-width to the bottom edge (taskbar mode only).
func redock() -> void:
	if not Settings.taskbar_mode:
		return
	var window := get_window()
	var rect := DisplayServer.screen_get_usable_rect(window.current_screen)
	if rect.size.x <= 0:
		return  # no usable display (e.g. headless) — nothing to dock to
	var height := HEIGHT_EXPANDED if _expanded else HEIGHT_IDLE
	window.size = Vector2i(rect.size.x, height)
	window.position = Vector2i(rect.position.x, rect.end.y - height)

func set_expanded(expanded: bool) -> void:
	if expanded == _expanded or not Settings.taskbar_mode:
		return  # only the docked taskbar resizes
	_expanded = expanded
	redock()

func toggle_expanded() -> void:
	set_expanded(not _expanded)

func is_expanded() -> bool:
	return _expanded
