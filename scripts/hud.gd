extends CanvasLayer

## Economy HUD (issue #18): phase, balance, population, happiness, selected zone,
## and the net rate colored by sign (green = earning, red = losing). On its own
## CanvasLayer so the day/night CanvasModulate doesn't tint the text.

var _label: Label
var _net: Label

func _ready() -> void:
	_label = _make_label(Vector2(12, 3))
	_label.add_theme_color_override("font_color", Color.WHITE)
	_net = _make_label(Vector2(0, 3))

func _make_label(pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	add_child(label)
	return label

func _process(_delta: float) -> void:
	var s := City.sim
	_label.text = "🗓 Ano %d   %s   $%d   👥 %d   😊 %d   🔨 %s    " % [
		s.year(), CitySim.PHASE_NAME[s.phase()],
		int(s.money), int(s.population), int(s.happiness()),
		CitySim.ZONE_NAME[City.selected_zone],
	]
	var net := s.net_per_sec()
	_net.text = "%+.1f $/s" % net
	_net.position.x = _label.position.x + _label.get_minimum_size().x
	_net.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if net >= 0.0 else Color(1.0, 0.45, 0.45))
