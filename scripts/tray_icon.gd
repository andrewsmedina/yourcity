extends Node

## System tray / macOS menu-bar status icon (issue #7).
##
## Uses DisplayServer's status indicator: the macOS menu bar and the Windows
## tray. Guarded by FEATURE_STATUS_INDICATOR, so headless runs and platforms
## without support (most Linux WMs) simply skip it. The menu lets the player
## reopen/focus the window and mute notifications; the blinking-on-crisis
## behavior builds on this in issue #35.

var muted := false

var _indicator_id := -1
var _menu_rid: RID

const _MENU_MUTE_INDEX := 1

func _ready() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR):
		return
	var icon := load("res://icon.svg") as Texture2D
	_indicator_id = DisplayServer.create_status_indicator(icon, "TaskbarCity", _on_indicator_pressed)
	_menu_rid = NativeMenu.create_menu()
	NativeMenu.add_item(_menu_rid, "Abrir TaskbarCity", _on_open)
	NativeMenu.add_item(_menu_rid, "Silenciar notificações", _on_toggle_mute)
	NativeMenu.add_separator(_menu_rid)
	NativeMenu.add_item(_menu_rid, "Sair", _on_quit)
	DisplayServer.status_indicator_set_menu(_indicator_id, _menu_rid)

func _on_indicator_pressed(_mouse_button: int, _click_position: Vector2i) -> void:
	_on_open()

func _on_open(_tag: Variant = null) -> void:
	var window := get_window()
	window.show()
	window.grab_focus()

func _on_toggle_mute(_tag: Variant = null) -> void:
	muted = not muted
	NativeMenu.set_item_text(
		_menu_rid, _MENU_MUTE_INDEX,
		"Reativar notificações" if muted else "Silenciar notificações"
	)

func _on_quit(_tag: Variant = null) -> void:
	get_tree().quit()

func _exit_tree() -> void:
	if _menu_rid.is_valid():
		NativeMenu.free_menu(_menu_rid)
	if _indicator_id != -1:
		DisplayServer.delete_status_indicator(_indicator_id)
