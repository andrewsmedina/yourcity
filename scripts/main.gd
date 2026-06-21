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
		" content_scale=", w.content_scale_factor)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var slot := int(event.position.x / _TILE_PX)
		print("[click] ", event.position, " -> slot ", slot)
		_try_build(slot)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			WindowManager.toggle_expanded()
		elif event.keycode == KEY_C:
			City.sim.indicators[CitySim.Indicator.SECURITY] = 10.0
		elif event.keycode == KEY_R:
			City.reset()
			print("[reset] fresh city: money=", City.sim.money)

func _try_build(slot: int) -> void:
	if slot < 0 or slot >= City.sim.slots.size():
		print("[build] slot ", slot, " out of range (", City.sim.slots.size(), " slots)")
		return
	if City.sim.slots[slot] != null:
		print("[build] slot ", slot, " already occupied")
		return
	var ok := City.build(CitySim.Zone.RESIDENTIAL, slot)
	print("[build] residential slot ", slot, " -> ", ok, "  money=", City.sim.money)
