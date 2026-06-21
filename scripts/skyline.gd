extends Node2D

## City skyline AND build grid (issues #10, #12, #16). Each column is a build
## slot mirrored from City.sim: locked slots are hidden, empty unlocked slots
## show a faint lot, built slots show their zone's tile and animate up from the
## ground when constructed. Clicking an empty lot opens a menu to pick a zone.

const PIXEL_SCALE := 3
const _GROW_TIME := 0.35

const ZONE_TILE := {
	CitySim.Zone.RESIDENTIAL: "house",
	CitySim.Zone.COMMERCIAL: "building_low",
	CitySim.Zone.INDUSTRIAL: "building_mid",
	CitySim.Zone.SERVICE: "building_high",
}
const ZONE_LABEL := {
	CitySim.Zone.RESIDENTIAL: "Residencial",
	CitySim.Zone.COMMERCIAL: "Comercial",
	CitySim.Zone.INDUSTRIAL: "Industrial",
	CitySim.Zone.SERVICE: "Serviços",
}
# Menu row order, so a PopupMenu item id maps back to a zone.
const MENU_ZONES := [
	CitySim.Zone.RESIDENTIAL, CitySim.Zone.COMMERCIAL,
	CitySim.Zone.INDUSTRIAL, CitySim.Zone.SERVICE,
]

var _tile_px := 0
var _baseline := 0.0
var _sprites: Array[Sprite2D] = []
var _buttons: Array[Button] = []
var _built_state: Array = []  # last-rendered slot contents, for change detection
var _menu: PopupMenu
var _pending_slot := -1

func _ready() -> void:
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	_baseline = get_viewport_rect().size.y
	_build_columns()
	_menu = PopupMenu.new()
	for z in MENU_ZONES:
		_menu.add_item("%s  ($%d)" % [ZONE_LABEL[z], int(CitySim.ZONE_COST[z])])
	_menu.id_pressed.connect(_on_menu_id_pressed)
	add_child(_menu)
	City.city_changed.connect(refresh)
	refresh()

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
		var btn := Button.new()
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.position = Vector2(i * _tile_px, 0)
		btn.size = Vector2(_tile_px, _baseline)
		btn.modulate = Color(1, 1, 1, 0)  # invisible click area over the lot
		btn.pressed.connect(_on_slot_pressed.bind(i))
		add_child(btn)
		_buttons.append(btn)
		_built_state.append(null)

## Re-sync every column with the simulation's slots.
func refresh() -> void:
	var sim := City.sim
	for i in _sprites.size():
		var spr := _sprites[i]
		var btn := _buttons[i]
		var unlocked := i < sim.slots.size()
		btn.disabled = not unlocked
		btn.visible = unlocked
		spr.visible = unlocked
		if not unlocked:
			_built_state[i] = null
			continue
		var zone = sim.slots[i]
		if zone == null:
			spr.texture = CityTiles.get_tile("ground")
			spr.modulate = Color(1, 1, 1, 0.5)
			spr.scale = Vector2(PIXEL_SCALE, PIXEL_SCALE)
			spr.position = Vector2(i * _tile_px, _baseline - _tile_px)
			_built_state[i] = null
		else:
			spr.texture = CityTiles.get_tile(ZONE_TILE[zone])
			spr.modulate = Color.WHITE
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

func _on_slot_pressed(slot_index: int) -> void:
	var sim := City.sim
	if slot_index >= sim.slots.size() or sim.slots[slot_index] != null:
		return
	_pending_slot = slot_index
	_menu.position = DisplayServer.mouse_get_position()
	_menu.reset_size()
	_menu.popup()

func _on_menu_id_pressed(id: int) -> void:
	if _pending_slot < 0:
		return
	City.build(MENU_ZONES[id], _pending_slot)  # emits city_changed -> refresh()
	_pending_slot = -1
