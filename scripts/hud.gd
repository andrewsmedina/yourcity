extends CanvasLayer

## Economy HUD (issue #18): phase, balance, population, happiness and net rate,
## plus a beginner hint while the city is still empty. On its own CanvasLayer so
## the day/night CanvasModulate doesn't tint the text.

var _label: Label
var _hint: Label

func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

	_hint = Label.new()
	_hint.position = Vector2(12, 28)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 4)
	_hint.text = "👆 Clique num lote (+) para construir  ·  Enter expande  ·  C força crise"
	add_child(_hint)

func _process(_delta: float) -> void:
	var s := City.sim
	_label.text = "%s   $%d   pop %d   fel %d   =  $%+.1f/s" % [
		CitySim.PHASE_NAME[s.phase()],
		int(s.money), int(s.population), int(s.happiness()), s.net_per_sec(),
	]
	# Hint stays until the player builds their first zone; hidden during a crisis
	# so it doesn't overlap the decision panel.
	_hint.visible = s.active_crises().is_empty() and s.slots.all(func(slot): return slot == null)
