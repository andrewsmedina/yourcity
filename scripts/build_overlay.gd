extends Control

## Build overlay (#16, #34). Draws a clear "+" marker on every empty buildable
## lot and turns clicks into builds via a zone menu. Lives on its own CanvasLayer
## so the markers stay bright regardless of the day/night tint and so GUI input
## works reliably (per-slot Buttons under the skyline Node2D did not). Full-rect,
## so it follows the window between idle (120) and expanded (300) automatically.

const PIXEL_SCALE := 3

const ZONE_LABEL := {
	CitySim.Zone.RESIDENTIAL: "Residencial",
	CitySim.Zone.COMMERCIAL: "Comercial",
	CitySim.Zone.INDUSTRIAL: "Industrial",
	CitySim.Zone.POLICE: "Delegacia",
	CitySim.Zone.SCHOOL: "Escola",
	CitySim.Zone.HOSPITAL: "Hospital",
	CitySim.Zone.ROADS: "Vias",
	CitySim.Zone.POWER: "Usina",
}
const SERVICE_ZONES := [
	CitySim.Zone.POLICE, CitySim.Zone.SCHOOL, CitySim.Zone.HOSPITAL,
	CitySim.Zone.ROADS, CitySim.Zone.POWER,
]

var _tile_px := 0
var _menu: PopupMenu
var _services: PopupMenu
var _pending_slot := -1

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	_build_menu()
	City.city_changed.connect(queue_redraw)

func _process(_delta: float) -> void:
	queue_redraw()  # slots unlock as population grows

func _draw() -> void:
	var sim := City.sim
	var baseline := size.y
	for i in sim.slots.size():
		if sim.slots[i] != null:
			continue  # built lots are drawn by the skyline
		var rect := Rect2(i * _tile_px + 3, baseline - _tile_px, _tile_px - 6, _tile_px - 4)
		draw_rect(rect, Color(0.2, 0.5, 0.85, 0.45), true)
		draw_rect(rect, Color(0.6, 0.85, 1.0, 0.95), false, 2.0)
		var c := rect.get_center()
		draw_line(c - Vector2(7, 0), c + Vector2(7, 0), Color.WHITE, 2.0)
		draw_line(c - Vector2(0, 7), c + Vector2(0, 7), Color.WHITE, 2.0)

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var slot := int(event.position.x / _tile_px)
	print("[build] click x=", event.position.x, " -> slot ", slot)
	if slot < 0 or slot >= City.sim.slots.size() or City.sim.slots[slot] != null:
		print("[build] slot ", slot, " not buildable (locked or occupied)")
		return
	_pending_slot = slot
	_refresh_menu_locks()
	_menu.position = DisplayServer.mouse_get_position()
	_menu.reset_size()
	_menu.popup()
	accept_event()

func _build_menu() -> void:
	_menu = PopupMenu.new()
	for z in [CitySim.Zone.RESIDENTIAL, CitySim.Zone.COMMERCIAL, CitySim.Zone.INDUSTRIAL]:
		_menu.add_item(_item_label(z), z)
	_services = PopupMenu.new()
	for z in SERVICE_ZONES:
		_services.add_item(_item_label(z), z)
	_services.id_pressed.connect(_on_menu_id_pressed)
	_menu.add_child(_services)
	_menu.add_submenu_node_item("Serviços", _services)
	_menu.id_pressed.connect(_on_menu_id_pressed)
	add_child(_menu)

func _refresh_menu_locks() -> void:
	for menu: PopupMenu in [_menu, _services]:
		for idx in menu.item_count:
			var id: int = menu.get_item_id(idx)
			if id < 0:
				continue  # the "Serviços" submenu entry, not a zone
			var unlocked := City.sim.is_zone_unlocked(id)
			menu.set_item_disabled(idx, not unlocked)
			var label := _item_label(id)
			if not unlocked:
				label += "  🔒 %s" % CitySim.PHASE_NAME[CitySim.ZONE_UNLOCK_PHASE[id]]
			menu.set_item_text(idx, label)

func _item_label(zone: int) -> String:
	return "%s  ($%d)" % [ZONE_LABEL[zone], int(CitySim.ZONE_COST[zone])]

func _on_menu_id_pressed(id: int) -> void:
	if _pending_slot < 0:
		return
	var ok := City.build(id, _pending_slot)
	print("[build] build zone ", id, " in slot ", _pending_slot, " -> ", ok)
	_pending_slot = -1
