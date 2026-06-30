extends CanvasLayer

## Crisis warning (issues #28, #31). A toast + sound when a crisis starts and a
## persistent banner telling the player which service to build to resolve it.
## There are no action buttons — a crisis is resolved by building that service
## on the grid (which raises the indicator back above the recovery threshold).

const _TIMER_W := 240.0
const _TIMER_H := 6.0

var _toast: Label
var _panel: PanelContainer
var _title: Label
var _timer_fill: ColorRect
var _sound: AudioStreamPlayer

func _ready() -> void:
	_toast = Label.new()
	_toast.position = Vector2(12, 4)
	_toast.modulate.a = 0.0
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 4)
	add_child(_toast)

	_panel = PanelContainer.new()
	_panel.position = Vector2(320, 90)  # in the play area, clear of the top bar/sidebar
	_panel.visible = false
	add_child(_panel)
	var vb := VBoxContainer.new()
	_panel.add_child(vb)
	_title = Label.new()
	_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 4)
	vb.add_child(_title)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(_TIMER_W, _TIMER_H)
	vb.add_child(holder)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.size = Vector2(_TIMER_W, _TIMER_H)
	holder.add_child(bg)
	_timer_fill = ColorRect.new()
	_timer_fill.color = Color(1.0, 0.4, 0.3)
	_timer_fill.size = Vector2(_TIMER_W, _TIMER_H)
	holder.add_child(_timer_fill)

	_sound = AudioStreamPlayer.new()
	_sound.stream = load("res://assets/notify.wav")
	add_child(_sound)

	City.crisis_started.connect(_on_crisis_started)

func _on_crisis_started(crisis) -> void:
	_flash_toast("⚠ %s!" % CitySim.CRISIS_TITLE[crisis])
	if not TrayIcon.muted:
		_sound.play()

func _process(_delta: float) -> void:
	var active := City.sim.active_crises()
	if active.is_empty():
		_panel.visible = false
		return
	var crisis = active[0]
	var fix: int = CitySim.SERVICE_FOR[CitySim.CRISIS_INDICATOR[crisis]]
	var key := fix + 1  # zone enum order matches keys 1-8
	var extra := active.size() - 1
	_title.add_theme_font_size_override("font_size", int(18 * Settings.ui_scale))
	_title.text = "🚨 %s — construa %s (tecla %d)%s" % [
		CitySim.CRISIS_TITLE[crisis], CitySim.ZONE_NAME[fix], key,
		"   (+%d em fila)" % extra if extra > 0 else "",
	]
	_timer_fill.size.x = _TIMER_W * clampf(
		City.sim.crisis_time_left(crisis) / CitySim.RESPONSE_WINDOW, 0.0, 1.0)
	_panel.visible = true

func _flash_toast(text: String) -> void:
	_toast.add_theme_font_size_override("font_size", int(18 * Settings.ui_scale))
	_toast.text = text
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
