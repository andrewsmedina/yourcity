extends Control

## Build grid (#16, #34): a GRID_COLS x GRID_ROWS grid of square lots. Empty
## unlocked lots show a pulsing "+", built lots show a colored square with the
## zone's first letter, locked lots are dimmed. Drawn on its own CanvasLayer so
## it stays crisp regardless of the day/night tint. Clicks are handled in
## main._input (GUI hit-testing is unreliable in this macOS borderless window).

const GRID_TOP := 80.0   # top bar (HUD) — not buildable
const GRID_LEFT := 300.0  # left sidebar (indicators) — not buildable; sync with IndicatorBars
const TILE := 48.0       # fixed lot size; the window height grows with row count
const PALETTE_ROW := 38.0
const PALETTE_FS := 18

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
var _zone_textures := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	_zone_textures[CitySim.Zone.ROADS] = load("res://assets/tile_street.png")
	_zone_textures[CitySim.Zone.RESIDENTIAL] = load("res://assets/tile_residential.png")
	_zone_textures[CitySim.Zone.HOSPITAL] = load("res://assets/tile_hospital.png")
	City.city_changed.connect(queue_redraw)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	# Local mouse position so clicks map to the space we draw in (macOS scaling).
	var p := get_local_mouse_position()
	if event.button_index == MOUSE_BUTTON_LEFT:
		if p.x < GRID_LEFT:  # sidebar: maybe a build-palette item
			for z in 8:
				if _palette_item_rect(z).has_point(p):
					City.selected_zone = z
					return
			return
		var slot := _slot_at(p)
		if slot >= 0 and City.sim.slots[slot] == null:
			City.build(City.selected_zone, slot)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		var slot := _slot_at(p)  # right-click bulldozes a built lot
		if slot >= 0 and City.sim.slots[slot] != null:
			City.demolish(slot)

## The slot index under a local point, or -1 if it's outside the build grid.
func _slot_at(p: Vector2) -> int:
	if p.x < GRID_LEFT or p.y < GRID_TOP:
		return -1
	var tile := tile_size()
	var col := int((p.x - GRID_LEFT) / tile)
	var row := int((p.y - GRID_TOP) / tile)
	if col < 0 or col >= CitySim.GRID_COLS or row < 0 or row >= CitySim.GRID_ROWS:
		return -1
	var slot := row * CitySim.GRID_COLS + col
	return slot if slot < City.sim.slots.size() else -1

## Fixed square lot size (the window is tall enough to hold all the rows).
func tile_size() -> float:
	return TILE

func _draw() -> void:
	var tile := tile_size()
	if tile <= 1.0:
		return  # not sized yet
	_draw_chrome()
	_draw_palette()
	var sim := City.sim
	var pulse := 0.55 + 0.35 * sin(_t * 4.0)
	for i in CitySim.MAX_SLOTS:
		var col := i % CitySim.GRID_COLS
		var row := i / CitySim.GRID_COLS
		var rect := Rect2(GRID_LEFT + col * tile + 1.0, GRID_TOP + row * tile + 1.0, tile - 2.0, tile - 2.0)
		if i >= sim.slots.size():
			_draw_locked(rect)  # not yet unlocked
		elif sim.slots[i] == null:
			_draw_empty(rect, pulse)
		else:
			_draw_building(rect, sim.slots[i], tile)

# Build palette lives below the indicators in the left sidebar.
func _palette_top() -> float:
	return 92.0 + 7.0 * (22.0 * Settings.ui_scale) + 24.0

func _palette_item_rect(i: int) -> Rect2:
	return Rect2(8.0, _palette_top() + i * PALETTE_ROW, GRID_LEFT - 16.0, PALETTE_ROW - 4.0)

func _draw_palette() -> void:
	draw_string(_font, Vector2(12.0, _palette_top() - 8.0), "CONSTRUIR (1-8) · dir = remover ($10)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.85, 0.95))
	for z in 8:
		var r := _palette_item_rect(z)
		var selected := int(City.selected_zone) == z
		draw_rect(r, Color(0.25, 0.45, 0.8, 0.55) if selected else Color(1, 1, 1, 0.06), true)
		if selected:
			draw_rect(r, Color(0.6, 0.85, 1.0, 0.95), false, 2.0)
		var sw := Rect2(r.position.x + 6.0, r.position.y + 5.0, r.size.y - 10.0, r.size.y - 10.0)
		if _zone_textures.has(z):
			draw_texture_rect(_zone_textures[z], sw, false)
		else:
			draw_rect(sw, ZONE_COLOR[z], true)
		draw_string(_font, Vector2(sw.end.x + 10.0, r.get_center().y + PALETTE_FS * 0.35),
			"%d  %s" % [z + 1, CitySim.ZONE_NAME[z]],
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x, PALETTE_FS, Color.WHITE)

# Dark panels for the non-buildable top bar and left sidebar.
func _draw_chrome() -> void:
	var w := maxf(size.x, DisplayServer.window_get_size().x)
	var h := maxf(size.y, DisplayServer.window_get_size().y)
	var chrome := Color(0.10, 0.12, 0.18, 0.9)
	draw_rect(Rect2(0, 0, w, GRID_TOP), chrome, true)       # top bar
	draw_rect(Rect2(0, 0, GRID_LEFT, h), chrome, true)      # left sidebar

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
	if _zone_textures.has(zone):
		draw_texture_rect(_zone_textures[zone], rect, false)
		return
	var color: Color = ZONE_COLOR[zone]
	draw_rect(rect, color, true)
	draw_rect(rect, color.darkened(0.4), false, 1.5)
	var letter: String = CitySim.ZONE_NAME[zone].substr(0, 1)
	var font_size := maxi(8, int(tile * 0.6))
	draw_string(_font, Vector2(rect.position.x, rect.get_center().y + font_size * 0.35),
		letter, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(0.1, 0.1, 0.1))
