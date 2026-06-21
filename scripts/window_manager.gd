extends Node

## Centralizes all window tweaks for the taskbar layout.
##
## Owns the window's appearance and placement so the rest of the game never
## touches DisplayServer directly. Today it makes the window borderless and
## always-on-top (issues #2 and #3); per-OS docking to the screen edge and the
## idle <-> expanded resize build on top of this in later issues.

func _ready() -> void:
	var window := get_window()
	window.borderless = true
	window.always_on_top = true
