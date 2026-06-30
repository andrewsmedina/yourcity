extends Control

## Colored indicator bars (issue #25): the five city indicators plus happiness,
## drawn in the left sidebar (not a buildable area). Full-rect but
## mouse-transparent so it never steals clicks. Scales with the UI scale.

const SIDEBAR_W := 300.0  # keep in sync with BuildOverlay.GRID_LEFT
const TOP_OFFSET := 92.0  # start below the top HUD bar (BuildOverlay.GRID_TOP)

var _rows: Array = []
var _font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = ThemeDB.fallback_font
	_rows = [
		{"label": "Seg", "color": Color(0.4, 0.6, 1.0), "ind": CitySim.Indicator.SECURITY},
		{"label": "Edu", "color": Color(0.4, 0.85, 0.5), "ind": CitySim.Indicator.EDUCATION},
		{"label": "Saú", "color": Color(1.0, 0.45, 0.45), "ind": CitySim.Indicator.HEALTH},
		{"label": "Trâ", "color": Color(1.0, 0.7, 0.3), "ind": CitySim.Indicator.TRAFFIC},
		{"label": "Ene", "color": Color(1.0, 0.9, 0.3), "ind": CitySim.Indicator.ENERGY},
	]

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var sim := City.sim
	var s: float = Settings.ui_scale
	var fs := int(14 * s)
	var bar_h := 14.0 * s
	var gap := 8.0 * s
	var margin := 12.0
	var label_w := 26.0 * s
	var value_w := 24.0 * s
	var bar_x := margin + label_w
	var bar_w := maxf(40.0, SIDEBAR_W - bar_x - value_w - margin)
	var y := TOP_OFFSET
	for row in _rows:
		_draw_bar(margin, bar_x, y, bar_w, bar_h, fs, row.label, sim.indicators[row.ind], row.color)
		y += bar_h + gap
	_draw_bar(margin, bar_x, y + 4.0 * s, bar_w, bar_h, fs, "Fel", sim.happiness(), Color.WHITE)

func _draw_bar(label_x: float, bar_x: float, y: float, bar_w: float, bar_h: float,
		fs: int, label: String, value: float, color: Color) -> void:
	var text_y := y + bar_h - 3.0
	draw_string(_font, Vector2(label_x, text_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	draw_rect(Rect2(bar_x, y, bar_w, bar_h), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(bar_x, y, bar_w * clampf(value / 100.0, 0.0, 1.0), bar_h), color)
	draw_string(_font, Vector2(bar_x + bar_w + 4.0, text_y), str(int(value)),
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
