extends Control

## Colored indicator bars (issue #25): the five city indicators plus happiness,
## drawn top-right. Full-rect but mouse-transparent so it never steals clicks
## from the build slots underneath.

const _BAR_W := 180.0
const _BAR_H := 18.0
const _GAP := 6.0
const _MARGIN := 10.0
const _LABEL_W := 58.0
const _VALUE_W := 38.0
const _FONT_SIZE := 16

var _rows: Array = []  # [{ label, color, getter:Callable }]
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
	var bar_w := _BAR_W * s
	var bar_h := _BAR_H * s
	var gap := _GAP * s
	var label_w := _LABEL_W * s
	var value_w := _VALUE_W * s
	var fs := int(_FONT_SIZE * s)
	var right := get_viewport_rect().size.x - _MARGIN * s
	var x := right - value_w - bar_w
	var label_x := x - label_w
	var y := _MARGIN * s
	for row in _rows:
		_draw_bar(label_x, x, y, bar_w, bar_h, fs, row.label, sim.indicators[row.ind], row.color)
		y += bar_h + gap
	_draw_bar(label_x, x, y + 3.0 * s, bar_w, bar_h, fs, "Fel", sim.happiness(), Color.WHITE)

func _draw_bar(label_x: float, x: float, y: float, bar_w: float, bar_h: float,
		fs: int, label: String, value: float, color: Color) -> void:
	var text_y := y + bar_h - 3.0
	draw_string(_font, Vector2(label_x, text_y), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	draw_rect(Rect2(x, y, bar_w, bar_h), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(x, y, bar_w * clampf(value / 100.0, 0.0, 1.0), bar_h), color)
	draw_string(_font, Vector2(x + bar_w + 4.0, text_y), str(int(value)),
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
