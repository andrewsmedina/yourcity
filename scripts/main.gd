extends Node2D

## Entry point for TaskbarCity. Confirms the project boots, offers a debug
## toggle for the idle <-> expanded resize (#8), and — until the economy drives
## it — slowly grows the skyline so its animation is visible (#10).

@onready var _skyline: Node2D = $Skyline

const _DEBUG_GROW_EVERY := 0.4

var _grow_accum := 0.0

func _ready() -> void:
	print("TaskbarCity booted — Godot ", Engine.get_version_info().string)

func _process(delta: float) -> void:
	_grow_accum += delta
	if _grow_accum >= _DEBUG_GROW_EVERY:
		_grow_accum = 0.0
		if _skyline.building_count < _skyline.capacity():
			_skyline.set_building_count(_skyline.building_count + 1)

func _unhandled_input(event: InputEvent) -> void:
	# Debug: Enter/Space toggles the expanded window height until the crisis
	# system drives it for real.
	if event.is_action_pressed("ui_accept"):
		WindowManager.toggle_expanded()
