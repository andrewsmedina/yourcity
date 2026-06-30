extends Node2D

## Entry point for TaskbarCity. Owns input (which reliably fires on macOS, unlike
## GUI hit-testing in this borderless window):
##   1-8        — select the zone to build
##   left click — build the selected zone on the lot under the cursor (#16)
##   Enter/Space — toggle the expanded window height (#8)
##   C           — force a Crime crisis (debug)
##   R           — reset to a fresh city (debug / recovery)

const _ZONE_KEYS := {
	KEY_1: CitySim.Zone.RESIDENTIAL,
	KEY_2: CitySim.Zone.COMMERCIAL,
	KEY_3: CitySim.Zone.INDUSTRIAL,
	KEY_4: CitySim.Zone.POLICE,
	KEY_5: CitySim.Zone.SCHOOL,
	KEY_6: CitySim.Zone.HOSPITAL,
	KEY_7: CitySim.Zone.ROADS,
	KEY_8: CitySim.Zone.POWER,
}

func _ready() -> void:
	print("TaskbarCity booted — Godot ", Engine.get_version_info().string)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_handle_key(event.keycode)

func _handle_key(keycode: int) -> void:
	if _ZONE_KEYS.has(keycode):
		City.selected_zone = _ZONE_KEYS[keycode]
	elif keycode == KEY_ENTER or keycode == KEY_SPACE:
		WindowManager.toggle_expanded()
	elif keycode == KEY_EQUAL or keycode == KEY_KP_ADD:
		Settings.bump(0.1)   # + aumenta a fonte/UI
	elif keycode == KEY_MINUS or keycode == KEY_KP_SUBTRACT:
		Settings.bump(-0.1)  # - diminui a fonte/UI
	elif keycode == KEY_C:
		City.sim.indicators[CitySim.Indicator.SECURITY] = 10.0
	elif keycode == KEY_BRACKETLEFT:
		City.sim.adjust_tax(-CitySim.TAX_STEP)  # [ baixa o imposto
	elif keycode == KEY_BRACKETRIGHT:
		City.sim.adjust_tax(CitySim.TAX_STEP)   # ] aumenta o imposto
	elif keycode == KEY_T:
		WindowManager.toggle_mode()  # alterna janela normal <-> taskbar
	elif keycode == KEY_R:
		City.reset()
