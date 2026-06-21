extends Node2D

## City skyline AND build grid (issues #10, #12, #16). Each column is a build
## slot mirrored from City.sim: locked slots are hidden, empty unlocked slots
## show a faint lot, built slots show their zone's tile (tinted per kind) and
## animate up from the ground when constructed.
##
## Clicks are captured by a Control on its own CanvasLayer (the canonical way to
## do GUI input in Godot) rather than per-slot buttons parented to this Node2D,
## which did not reliably receive input.

const PIXEL_SCALE := 3
const _GROW_TIME := 0.35

const ZONE_TILE := {
	CitySim.Zone.RESIDENTIAL: "house",
	CitySim.Zone.COMMERCIAL: "building_low",
	CitySim.Zone.INDUSTRIAL: "building_mid",
	CitySim.Zone.POLICE: "building_high",
	CitySim.Zone.SCHOOL: "building_high",
	CitySim.Zone.HOSPITAL: "building_high",
	CitySim.Zone.ROADS: "road",
	CitySim.Zone.POWER: "building_high",
}
const ZONE_TINT := {
	CitySim.Zone.RESIDENTIAL: Color.WHITE,
	CitySim.Zone.COMMERCIAL: Color.WHITE,
	CitySim.Zone.INDUSTRIAL: Color.WHITE,
	CitySim.Zone.POLICE: Color(0.5, 0.6, 1.0),
	CitySim.Zone.SCHOOL: Color(1.0, 0.85, 0.3),
	CitySim.Zone.HOSPITAL: Color(1.0, 0.5, 0.5),
	CitySim.Zone.ROADS: Color(0.8, 0.8, 0.8),
	CitySim.Zone.POWER: Color(0.5, 1.0, 0.6),
}
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
var _baseline := 0.0
var _sprites: Array[Sprite2D] = []
var _built_state: Array = []  # last-rendered slot contents, for change detection
var _menu: PopupMenu
var _services: PopupMenu
var _pending_slot := -1

func _ready() -> void:
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	_baseline = get_viewport_rect().size.y
	_build_columns()
	_build_menu()
	_build_input_layer()
	City.city_changed.connect(refresh)
	get_viewport().size_changed.connect(_reflow)
	refresh()

func _build_input_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0  # below HUD/crisis so the crisis panel keeps click priority
	add_child(layer)
	var ctl := Control.new()
	ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctl.mouse_filter = Control.MOUSE_FILTER_PASS
	ctl.gui_input.connect(_on_build_input)
	layer.add_child(ctl)

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

## Disable zones not yet unlocked at the current phase, with a lock hint (#39).
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

func _build_columns() -> void:
	var width := int(get_viewport_rect().size.x)
	var count := int(ceil(float(width) / _tile_px))
	for i in count:
		var spr := Sprite2D.new()
		spr.centered = false
		spr.scale = Vector2(PIXEL_SCALE, 0.0)
		spr.position = Vector2(i * _tile_px, _baseline)
		add_child(spr)
		_sprites.append(spr)
		_built_state.append(null)

## Re-anchor columns to the bottom when the window resizes (idle <-> expanded).
func _reflow() -> void:
	_baseline = get_viewport_rect().size.y
	refresh()

## Re-sync every column with the simulation's slots.
func refresh() -> void:
	var sim := City.sim
	for i in _sprites.size():
		var spr := _sprites[i]
		var unlocked := i < sim.slots.size()
		spr.visible = unlocked
		if not unlocked:
			_built_state[i] = null
			continue
		var zone = sim.slots[i]
		if zone == null:
			# Empty buildable lot — tint it light blue so it reads as clickable.
			spr.texture = CityTiles.get_tile("ground")
			spr.modulate = Color(0.7, 0.9, 1.0, 0.65)
			spr.scale = Vector2(PIXEL_SCALE, PIXEL_SCALE)
			spr.position = Vector2(i * _tile_px, _baseline - _tile_px)
			_built_state[i] = null
		else:
			spr.texture = CityTiles.get_tile(ZONE_TILE[zone])
			spr.modulate = ZONE_TINT[zone]
			if _built_state[i] != zone:
				_animate_build(spr)
			else:
				spr.scale = Vector2(PIXEL_SCALE, PIXEL_SCALE)
				spr.position = Vector2(i * _tile_px, _baseline - _tile_px)
			_built_state[i] = zone

func _animate_build(spr: Sprite2D) -> void:
	spr.scale = Vector2(PIXEL_SCALE, 0.0)
	spr.position.y = _baseline
	var tween := create_tween().set_parallel(true)
	tween.tween_property(spr, "scale:y", float(PIXEL_SCALE), _GROW_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "position:y", _baseline - _tile_px, _GROW_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_build_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var slot_index := int(event.position.x / _tile_px)
	print("[build] click at x=", event.position.x, " -> slot ", slot_index)
	_on_slot_pressed(slot_index)

func _on_slot_pressed(slot_index: int) -> void:
	var sim := City.sim
	if slot_index < 0 or slot_index >= sim.slots.size() or sim.slots[slot_index] != null:
		print("[build] slot ", slot_index, " not buildable (locked or occupied)")
		return
	_pending_slot = slot_index
	_refresh_menu_locks()
	_menu.position = DisplayServer.mouse_get_position()
	_menu.reset_size()
	_menu.popup()

func _on_menu_id_pressed(id: int) -> void:
	if _pending_slot < 0:
		return
	var ok := City.build(id, _pending_slot)  # id is the Zone value
	print("[build] build zone ", id, " in slot ", _pending_slot, " -> ", ok)
	_pending_slot = -1
