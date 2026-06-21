extends Control

## Build overlay (#16, #34): draws a clear, pulsing "+" marker on every empty
## buildable lot so they're impossible to miss in the wide bar. Lives on its own
## CanvasLayer so markers stay bright regardless of the day/night tint. Click
## handling lives in main._input.

const PIXEL_SCALE := 3

var _tile_px := 0
var _t := 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	City.city_changed.connect(queue_redraw)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var sim := City.sim
	var h := size.y
	var pulse := 0.55 + 0.35 * sin(_t * 4.0)
	for i in sim.slots.size():
		if sim.slots[i] != null:
			continue  # built lots are drawn by the skyline
		# Same footprint as the building that will replace it (bottom of the
		# bar), so the building appears exactly where the "+" was.
		var rect := Rect2(i * _tile_px + 2, h - _tile_px, _tile_px - 4, _tile_px - 2)
		draw_rect(rect, Color(0.2, 0.5, 0.85, 0.30 + 0.25 * pulse), true)
		draw_rect(rect, Color(0.6, 0.85, 1.0, pulse), false, 2.0)
		var c := rect.get_center()
		draw_line(c - Vector2(8, 0), c + Vector2(8, 0), Color(1, 1, 1, pulse), 3.0)
		draw_line(c - Vector2(0, 8), c + Vector2(0, 8), Color(1, 1, 1, pulse), 3.0)
