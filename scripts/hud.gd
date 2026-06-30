extends CanvasLayer

## Economy HUD (issue #18): phase, balance, population, happiness, tax, selected
## zone, plus the projected yearly balance (colored by sign) and a flash report
## when the year's budget is settled. On its own CanvasLayer so the day/night
## CanvasModulate doesn't tint the text.

var _label: Label
var _net: Label
var _report: Label
var _sound: AudioStreamPlayer

func _ready() -> void:
	_label = _make_label(Vector2(12, 3))
	_label.add_theme_color_override("font_color", Color.WHITE)
	_net = _make_label(Vector2(0, 3))
	_report = _make_label(Vector2(340, 92))  # in the play area, below the top bar
	_report.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	_report.modulate.a = 0.0
	_sound = AudioStreamPlayer.new()
	_sound.stream = load("res://assets/notify.wav")
	add_child(_sound)
	Settings.changed.connect(_apply_scale)
	City.year_passed.connect(_on_year_passed)
	_apply_scale()

func _apply_scale() -> void:
	var fs := int(22 * Settings.ui_scale)
	_label.add_theme_font_size_override("font_size", fs)
	_net.add_theme_font_size_override("font_size", fs)
	_report.add_theme_font_size_override("font_size", fs)

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
	_label.text = "🗓 Ano %d Mês %d   %s   $%d   👥 %d/%d   😊 %d   🏛 %d%% [/]   🔨 %s    " % [
		s.year(), s.month(), CitySim.PHASE_NAME[s.phase()],
		int(s.money), int(s.population), int(s.housing_capacity()), int(s.happiness()),
		int(s.tax_rate * 100.0), CitySim.ZONE_NAME[City.selected_zone],
	]
	# Tax is collected yearly, so show the projected balance for the year.
	var per_year := s.net_per_sec() * CitySim.YEAR
	_net.text = "≈ %+d $/ano" % int(per_year)
	_net.position.x = _label.position.x + _label.get_minimum_size().x
	_net.add_theme_color_override("font_color",
		Color(0.4, 1.0, 0.5) if per_year >= 0.0 else Color(1.0, 0.45, 0.45))

func _on_year_passed(year: int, tax: float, upkeep: float) -> void:
	var net := tax - upkeep
	print("[year] Ano ", year - 1, ": +$", int(tax), " impostos -$", int(upkeep),
		" manutenção = $", int(net))
	_report.text = "📊 Ano %d: +$%d impostos − $%d manutenção = $%+d" % [
		year - 1, int(tax), int(upkeep), int(net)]
	_report.modulate.a = 1.0
	if not TrayIcon.muted:
		_sound.play()
	_os_notify("TaskbarCity — Ano %d" % (year - 1),
		"Balanço: +$%d impostos − $%d manutenção = $%+d" % [int(tax), int(upkeep), int(net)])

## Fire a native OS notification (macOS Notification Center via osascript).
func _os_notify(title: String, body: String) -> void:
	if OS.get_name() != "macOS":
		return
	var safe_body := body.replace('"', "'")
	var safe_title := title.replace('"', "'")
	OS.create_process("osascript", [
		"-e", 'display notification "%s" with title "%s"' % [safe_body, safe_title],
	])
	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(_report, "modulate:a", 0.0, 0.8)
