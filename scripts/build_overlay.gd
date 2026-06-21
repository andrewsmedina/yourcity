extends Control

## Build grid (#16, #34): a GRID_COLS x GRID_ROWS grid of square lots. Empty
## unlocked lots show a pulsing "+", built lots show a colored square with the
## zone's first letter, locked lots are dimmed. Drawn on its own CanvasLayer so
## it stays crisp regardless of the day/night tint. Clicks are handled in
## main._input (GUI hit-testing is unreliable in this macOS borderless window).

const GRID_TOP := 22.0  # leave room for the HUD line at the top

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

var _t := 0.0
var _font: Font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	City.city_changed.connect(queue_redraw)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

## Square tile size that fits GRID_ROWS rows below the HUD line.
func tile_size() -> float:
	return (size.y - GRID_TOP) / CitySim.GRID_ROWS

func _draw() -> void:
	var sim := City.sim
	var tile := tile_size()
	var pulse := 0.55 + 0.35 * sin(_t * 4.0)
	for i in CitySim.MAX_SLOTS:
		var col := i % CitySim.GRID_COLS
		var row := i / CitySim.GRID_COLS
		var rect := Rect2(col * tile + 1.0, GRID_TOP + row * tile + 1.0, tile - 2.0, tile - 2.0)
		if i >= sim.slots.size():
			_draw_locked(rect)  # not yet unlocked
		elif sim.slots[i] == null:
			_draw_empty(rect, pulse)
		else:
			_draw_building(rect, sim.slots[i], tile)

func _draw_locked(rect: Rect2) -> void:
	draw_rect(rect, Color(1, 1, 1, 0.05), true)
	draw_rect(rect, Color(1, 1, 1, 0.10), false, 1.0)

func _draw_empty(rect: Rect2, pulse: float) -> void:
	draw_rect(rect, Color(0.2, 0.5, 0.85, 0.25 + 0.20 * pulse), true)
	draw_rect(rect, Color(0.6, 0.85, 1.0, pulse), false, 1.5)
	var c := rect.get_center()
	var s := rect.size.x * 0.22
	draw_line(c - Vector2(s, 0), c + Vector2(s, 0), Color(1, 1, 1, pulse), 2.0)
	draw_line(c - Vector2(0, s), c + Vector2(0, s), Color(1, 1, 1, pulse), 2.0)

func _draw_building(rect: Rect2, zone: int, tile: float) -> void:
	var color: Color = ZONE_COLOR[zone]
	draw_rect(rect, color, true)
	draw_rect(rect, color.darkened(0.4), false, 1.5)
	var letter: String = CitySim.ZONE_NAME[zone].substr(0, 1)
	var font_size := int(tile * 0.6)
	draw_string(_font, Vector2(rect.position.x, rect.get_center().y + font_size * 0.35),
		letter, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(0.1, 0.1, 0.1))
