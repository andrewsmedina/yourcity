extends Control

## Colored indicator bars (issue #25): the five city indicators plus happiness,
## drawn top-right. Full-rect but mouse-transparent so it never steals clicks
## from the build slots underneath.

const _BAR_W := 70.0
const _BAR_H := 7.0
const _GAP := 3.0
const _MARGIN := 10.0
const _LABEL_W := 34.0

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
	var right := get_viewport_rect().size.x - _MARGIN
	var x := right - _BAR_W
	var label_x := x - _LABEL_W
	var y := _MARGIN
	for row in _rows:
		_draw_bar(label_x, x, y, row.label, sim.indicators[row.ind] / 100.0, row.color)
		y += _BAR_H + _GAP
	# Happiness summary bar.
	_draw_bar(label_x, x, y + 2.0, "Fel", sim.happiness() / 100.0, Color.WHITE)

func _draw_bar(label_x: float, x: float, y: float, label: String, fill: float, color: Color) -> void:
	draw_string(_font, Vector2(label_x, y + _BAR_H), label,
		HORIZONTAL_ALIGNMENT_LEFT, _LABEL_W, 9, Color.WHITE)
	draw_rect(Rect2(x, y, _BAR_W, _BAR_H), Color(0, 0, 0, 0.5))
	draw_rect(Rect2(x, y, _BAR_W * clampf(fill, 0.0, 1.0), _BAR_H), color)
