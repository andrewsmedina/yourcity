extends Control

## Build overlay (#16, #34). Draws a clear "+" marker on every empty buildable
## lot. Lives on its own CanvasLayer so markers stay bright regardless of the
## day/night tint.
##
## DIAGNOSTIC MODE: clicking an empty lot builds a Residential zone directly,
## using _input (which sees any click the window receives, bypassing GUI
## hit-testing) so we can confirm whether clicks reach the game at all on macOS.
## The zone-picker menu returns once input is confirmed working.

const PIXEL_SCALE := 3

var _tile_px := 0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	City.city_changed.connect(queue_redraw)

func _process(_delta: float) -> void:
	queue_redraw()  # slots unlock as population grows

func _draw() -> void:
	var sim := City.sim
	var baseline := size.y
	for i in sim.slots.size():
		if sim.slots[i] != null:
			continue  # built lots are drawn by the skyline
		var rect := Rect2(i * _tile_px + 3, baseline - _tile_px, _tile_px - 6, _tile_px - 4)
		draw_rect(rect, Color(0.2, 0.5, 0.85, 0.45), true)
		draw_rect(rect, Color(0.6, 0.85, 1.0, 0.95), false, 2.0)
		var c := rect.get_center()
		draw_line(c - Vector2(7, 0), c + Vector2(7, 0), Color.WHITE, 2.0)
		draw_line(c - Vector2(0, 7), c + Vector2(0, 7), Color.WHITE, 2.0)

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not City.sim.active_crises().is_empty():
		return  # let the crisis panel handle clicks
	var slot := int(event.position.x / _tile_px)
	print("[build] click at ", event.position, " -> slot ", slot)
	if slot < 0 or slot >= City.sim.slots.size() or City.sim.slots[slot] != null:
		print("[build] slot ", slot, " not buildable (locked or occupied)")
		return
	var ok := City.build(CitySim.Zone.RESIDENTIAL, slot)
	print("[build] build residential in slot ", slot, " -> ", ok)
