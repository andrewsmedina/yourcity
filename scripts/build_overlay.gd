extends Control

## Build grid (#16, #34). Each slot is a square the size of the "+" marker:
## empty lots show a pulsing "+", built lots show a colored square with the
## zone's first letter (R/C/I/D/E/H/V/U). Drawn on its own CanvasLayer so it
## stays crisp and readable regardless of the day/night tint. Clicks are handled
## in main._input (GUI hit-testing is unreliable in this macOS borderless window).

const PIXEL_SCALE := 3

const ZONE_COLOR := {
	CitySim.Zone.RESIDENTIAL: Color(0.40, 0.80, 0.50),
	CitySim.Zone.COMMERCIAL: Color(0.95, 0.80, 0.30),
	CitySim.Zone.INDUSTRIAL: Color(0.90, 0.60, 0.30),
	CitySim.Zone.POLICE: Color(0.50, 0.60, 1.00),
	CitySim.Zone.SCHOOL: Color(0.40, 0.80, 0.80),
	CitySim.Zone.HOSPITAL: Color(1.00, 0.50, 0.50),
	CitySim.Zone.ROADS: Color(0.70, 0.70, 0.70),
	CitySim.Zone.POWER: Color(0.60, 1.00, 0.50),
}

var _tile_px := 0
var _t := 0.0
var _font: Font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	_font = ThemeDB.fallback_font
	City.city_changed.connect(queue_redraw)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var sim := City.sim
	var h := size.y
	var pulse := 0.55 + 0.35 * sin(_t * 4.0)
	for i in sim.slots.size():
		var rect := Rect2(i * _tile_px + 2, h - _tile_px, _tile_px - 4, _tile_px - 2)
		var zone = sim.slots[i]
		if zone == null:
			_draw_empty_lot(rect, pulse)
		else:
			_draw_building(rect, zone)

func _draw_empty_lot(rect: Rect2, pulse: float) -> void:
	draw_rect(rect, Color(0.2, 0.5, 0.85, 0.30 + 0.25 * pulse), true)
	draw_rect(rect, Color(0.6, 0.85, 1.0, pulse), false, 2.0)
	var c := rect.get_center()
	draw_line(c - Vector2(8, 0), c + Vector2(8, 0), Color(1, 1, 1, pulse), 3.0)
	draw_line(c - Vector2(0, 8), c + Vector2(0, 8), Color(1, 1, 1, pulse), 3.0)

func _draw_building(rect: Rect2, zone: int) -> void:
	var color: Color = ZONE_COLOR[zone]
	draw_rect(rect, color, true)
	draw_rect(rect, color.darkened(0.4), false, 2.0)
	var letter: String = CitySim.ZONE_NAME[zone].substr(0, 1)
	var font_size := 26
	var baseline := rect.get_center() + Vector2(0, font_size * 0.35)
	draw_string(_font, Vector2(rect.position.x, baseline.y), letter,
		HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(0.1, 0.1, 0.1))
