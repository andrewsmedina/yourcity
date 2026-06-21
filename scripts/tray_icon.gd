extends Node

## System tray / macOS menu-bar status icon (issue #7), which blinks while a
## crisis is active (issue #35) and lets the player mute notifications (#37).
##
## Uses DisplayServer's status indicator: the macOS menu bar and the Windows
## tray. Guarded by FEATURE_STATUS_INDICATOR, so headless runs and platforms
## without support (most Linux WMs) simply skip it.

var muted := false

var _indicator_id := -1
var _menu_rid: RID
var _icon_normal: Texture2D
var _icon_alert: Texture2D
var _blink_on := false

const _MENU_MUTE_INDEX := 1

func _ready() -> void:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR):
		return
	_icon_normal = load("res://icon.svg")
	_icon_alert = load("res://icon_alert.svg")
	_indicator_id = DisplayServer.create_status_indicator(_icon_normal, "TaskbarCity", _on_indicator_pressed)
	_menu_rid = NativeMenu.create_menu()
	NativeMenu.add_item(_menu_rid, "Abrir TaskbarCity", _on_open)
	NativeMenu.add_item(_menu_rid, "Silenciar notificações", _on_toggle_mute)
	NativeMenu.add_separator(_menu_rid)
	NativeMenu.add_item(_menu_rid, "Sair", _on_quit)
	DisplayServer.status_indicator_set_menu(_indicator_id, _menu_rid)

	City.crisis_started.connect(_refresh_blink)
	City.crisis_ended.connect(_refresh_blink)
	var blink := Timer.new()
	blink.wait_time = 0.5
	blink.autostart = true
	blink.timeout.connect(_on_blink_tick)
	add_child(blink)

func _refresh_blink(_crisis = null) -> void:
	# When no crisis remains, restore the normal icon immediately.
	if _indicator_id != -1 and City.sim.active_crises().is_empty():
		_blink_on = false
		DisplayServer.status_indicator_set_icon(_indicator_id, _icon_normal)

func _on_blink_tick() -> void:
	if _indicator_id == -1 or City.sim.active_crises().is_empty():
		return
	_blink_on = not _blink_on
	DisplayServer.status_indicator_set_icon(_indicator_id, _icon_alert if _blink_on else _icon_normal)

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
