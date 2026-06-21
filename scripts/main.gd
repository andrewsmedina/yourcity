extends Node2D

## Entry point for TaskbarCity. For now it only confirms the project boots.
## Window docking / borderless / always-on-top is handled in later issues.

func _ready() -> void:
	print("TaskbarCity booted — Godot ", Engine.get_version_info().string)
