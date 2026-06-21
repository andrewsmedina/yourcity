extends Node2D

## Entry point for TaskbarCity. Confirms the project boots and offers a debug
## toggle for the idle <-> expanded resize (#8). The skyline now grows from
## real construction (#16), so the old debug grow loop is gone.

func _ready() -> void:
	print("TaskbarCity booted — Godot ", Engine.get_version_info().string)

func _unhandled_input(event: InputEvent) -> void:
	# Debug: Enter/Space toggles the expanded window height until the crisis
	# system drives it for real.
	if event.is_action_pressed("ui_accept"):
		WindowManager.toggle_expanded()
