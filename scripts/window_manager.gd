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

const HEIGHT_IDLE := 180
const HEIGHT_EXPANDED := 360

var _expanded := false

func _ready() -> void:
	var window := get_window()
	window.borderless = true
	window.always_on_top = true
	redock()

## Pin the window full-width to the bottom edge of the screen it is on,
## at the current idle/expanded height.
func redock() -> void:
	var window := get_window()
	var rect := DisplayServer.screen_get_usable_rect(window.current_screen)
	if rect.size.x <= 0:
		return  # no usable display (e.g. headless) — nothing to dock to
	var height := HEIGHT_EXPANDED if _expanded else HEIGHT_IDLE
	window.size = Vector2i(rect.size.x, height)
	window.position = Vector2i(rect.position.x, rect.end.y - height)

func set_expanded(expanded: bool) -> void:
	if expanded == _expanded:
		return
	_expanded = expanded
	redock()

func toggle_expanded() -> void:
	set_expanded(not _expanded)

func is_expanded() -> bool:
	return _expanded
