extends Node

## User settings, persisted to disk. Currently just a UI scale the player can
## change at runtime (+/- keys) so the text is readable at any size.

signal changed

const PATH := "user://settings.json"
const MIN := 0.7
const MAX := 3.0

var ui_scale := 2.3  # default already enlarged (~10 "+" presses)
var taskbar_mode := false  # false = normal window (default); true = docked taskbar

func _ready() -> void:
	load_settings()

func bump(delta: float) -> void:
	ui_scale = clampf(ui_scale + delta, MIN, MAX)
	save_settings()
	changed.emit()

func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"ui_scale": ui_scale, "taskbar_mode": taskbar_mode}))
		f.close()

func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	if data.has("ui_scale"):
		ui_scale = clampf(float(data["ui_scale"]), MIN, MAX)
	if data.has("taskbar_mode"):
		taskbar_mode = bool(data["taskbar_mode"])
