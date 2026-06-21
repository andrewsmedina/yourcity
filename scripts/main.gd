extends Node2D

## Entry point for TaskbarCity. Confirms the project boots and provides a couple
## of debug shortcuts for manual testing until the real game flow drives them:
##   Enter/Space — toggle the expanded window height (#8)
##   C           — tank Security to force a Crime crisis (#26-#31)

func _ready() -> void:
	print("TaskbarCity booted — Godot ", Engine.get_version_info().string)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		WindowManager.toggle_expanded()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_C:
		City.sim.indicators[CitySim.Indicator.SECURITY] = 10.0
