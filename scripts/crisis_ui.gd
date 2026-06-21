extends CanvasLayer

## Crisis UI (issues #28, #29, #31): a toast when a crisis starts, a decision
## panel with the 2-3 response options, and an urgency timer bar. The window
## expands while any crisis is active and collapses when they're all resolved.
## Reads everything from City/CitySim; building the response just calls
## City.respond().

const _TIMER_W := 220.0
const _TIMER_H := 6.0

var _toast: Label
var _panel: PanelContainer
var _title: Label
var _timer_fill: ColorRect
var _buttons_box: HBoxContainer
var _current = null  # crisis currently shown in the panel, or null

func _ready() -> void:
	_toast = Label.new()
	_toast.position = Vector2(12, 4)
	_toast.modulate.a = 0.0
	_toast.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 4)
	add_child(_toast)

	_panel = PanelContainer.new()
	_panel.position = Vector2(8, 32)
	_panel.visible = false
	add_child(_panel)
	var vb := VBoxContainer.new()
	_panel.add_child(vb)
	_title = Label.new()
	vb.add_child(_title)
	var timer_holder := Control.new()
	timer_holder.custom_minimum_size = Vector2(_TIMER_W, _TIMER_H)
	vb.add_child(timer_holder)
	var timer_bg := ColorRect.new()
	timer_bg.color = Color(0, 0, 0, 0.5)
	timer_bg.size = Vector2(_TIMER_W, _TIMER_H)
	timer_holder.add_child(timer_bg)
	_timer_fill = ColorRect.new()
	_timer_fill.color = Color(1.0, 0.4, 0.3)
	_timer_fill.size = Vector2(_TIMER_W, _TIMER_H)
	timer_holder.add_child(_timer_fill)
	_buttons_box = HBoxContainer.new()
	vb.add_child(_buttons_box)

	City.crisis_started.connect(_on_crisis_started)

func _on_crisis_started(crisis) -> void:
	_flash_toast("⚠ %s!" % CitySim.CRISIS_TITLE[crisis])

func _process(_delta: float) -> void:
	var active := City.sim.active_crises()
	if active.is_empty():
		if _panel.visible:
			_panel.visible = false
			_current = null
			WindowManager.set_expanded(false)
		return
	var crisis = active[0]  # show the first active crisis
	WindowManager.set_expanded(true)
	if crisis != _current:
		_current = crisis
		_rebuild_panel(crisis)
	_panel.visible = true
	_timer_fill.size.x = _TIMER_W * clampf(
		City.sim.crisis_time_left(crisis) / CitySim.RESPONSE_WINDOW, 0.0, 1.0)
	_update_affordability(crisis)

func _rebuild_panel(crisis) -> void:
	var extra := City.sim.active_crises().size() - 1
	_title.text = "🚨 %s%s" % [
		CitySim.CRISIS_TITLE[crisis],
		"  (+%d em fila)" % extra if extra > 0 else "",
	]
	for child in _buttons_box.get_children():
		child.queue_free()
	var responses := City.sim.responses_for(crisis)
	for i in responses.size():
		var btn := Button.new()
		btn.text = "%s ($%d)" % [responses[i].label, int(responses[i].cost)]
		btn.pressed.connect(City.respond.bind(crisis, i))
		_buttons_box.add_child(btn)

func _update_affordability(crisis) -> void:
	var responses := City.sim.responses_for(crisis)
	var i := 0
	for child in _buttons_box.get_children():
		if child is Button:
			child.disabled = City.sim.money < responses[i].cost
			i += 1

func _flash_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_toast, "modulate:a", 0.0, 0.6)
