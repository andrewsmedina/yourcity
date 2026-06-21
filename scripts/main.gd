extends Node2D

## Entry point for TaskbarCity. Confirms the project boots and provides debug
## shortcuts. Build handling lives here (in _input, which reliably fires) while
## we sort out macOS input/scaling.
##   left click on a lot — build Residential (diagnostic; menu returns later)
##   Enter/Space — toggle the expanded window height (#8)
##   C           — tank Security to force a Crime crisis (#26-#31)

const _TILE_PX := 48  # CityTiles.TILE(16) * skyline PIXEL_SCALE(3)

func _ready() -> void:
	print("TaskbarCity booted — Godot ", Engine.get_version_info().string)
	var w := get_window()
	print("[geom] window.size=", w.size, " viewport=", get_viewport_rect().size,
		" content_scale=", w.content_scale_factor,
		" usable=", DisplayServer.screen_get_usable_rect(w.current_screen))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_build(event.position)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			WindowManager.toggle_expanded()
		elif event.keycode == KEY_C:
			City.sim.indicators[CitySim.Indicator.SECURITY] = 10.0

func _try_build(pos: Vector2) -> void:
	if not City.sim.active_crises().is_empty():
		return  # let the crisis panel take the click
	var slot := int(pos.x / _TILE_PX)
	print("[build] click ", pos, " -> slot ", slot)
	if slot < 0 or slot >= City.sim.slots.size() or City.sim.slots[slot] != null:
		print("[build] slot ", slot, " not buildable")
		return
	var ok := City.build(CitySim.Zone.RESIDENTIAL, slot)
	print("[build] residential -> ", ok)
