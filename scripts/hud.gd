extends CanvasLayer

## Economy HUD (issue #18): balance, population, income, costs and net rate.
## On its own CanvasLayer so the day/night CanvasModulate doesn't tint the text.

var _label: Label

func _ready() -> void:
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

func _process(_delta: float) -> void:
	var s := City.sim
	_label.text = "$%d   pop %d   fel %d   =  $%+.1f/s" % [
		int(s.money), int(s.population), int(s.happiness()), s.net_per_sec(),
	]
