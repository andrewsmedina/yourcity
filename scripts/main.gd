extends Node2D

## Entry point for TaskbarCity. Owns input (which reliably fires on macOS, unlike
## GUI hit-testing in this borderless window):
##   1-8        — select the zone to build
##   left click — build the selected zone on the lot under the cursor (#16)
##   Enter/Space — toggle the expanded window height (#8)
##   C           — force a Crime crisis (debug)
##   R           — reset to a fresh city (debug / recovery)

const _TILE_PX := 48  # CityTiles.TILE(16) * skyline PIXEL_SCALE(3)

const _ZONE_KEYS := {
	KEY_1: CitySim.Zone.RESIDENTIAL,
	KEY_2: CitySim.Zone.COMMERCIAL,
	KEY_3: CitySim.Zone.INDUSTRIAL,
	KEY_4: CitySim.Zone.POLICE,
	KEY_5: CitySim.Zone.SCHOOL,
	KEY_6: CitySim.Zone.HOSPITAL,
	KEY_7: CitySim.Zone.ROADS,
	KEY_8: CitySim.Zone.POWER,
}

func _ready() -> void:
	print("TaskbarCity booted — Godot ", Engine.get_version_info().string)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_build_at(event.position.x)
	elif event is InputEventKey and event.pressed:
		_handle_key(event.keycode)

func _build_at(x: float) -> void:
	if not City.sim.active_crises().is_empty():
		return  # leave clicks for the crisis flow while one is active
	var slot := int(x / _TILE_PX)
	if slot < 0 or slot >= City.sim.slots.size() or City.sim.slots[slot] != null:
		return
	City.build(City.selected_zone, slot)

func _handle_key(keycode: int) -> void:
	if _ZONE_KEYS.has(keycode):
		City.selected_zone = _ZONE_KEYS[keycode]
	elif keycode == KEY_ENTER or keycode == KEY_SPACE:
		WindowManager.toggle_expanded()
	elif keycode == KEY_C:
		City.sim.indicators[CitySim.Indicator.SECURITY] = 10.0
	elif keycode == KEY_R:
		City.reset()
