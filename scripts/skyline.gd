extends Node2D

## City skyline (issues #10, #12). Renders the built buildings mirrored from
## City.sim: each occupied slot shows its zone's tile (tinted per kind) and
## animates up from the ground when constructed. Empty/buildable lots and click
## handling live in BuildOverlay; day/night tint lives in DayNight.

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

var _tile_px := 0
var _baseline := 0.0
var _sprites: Array[Sprite2D] = []
var _built_state: Array = []  # last-rendered slot contents, for change detection

func _ready() -> void:
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	_baseline = get_viewport_rect().size.y
	_build_columns()
	City.city_changed.connect(refresh)
	get_viewport().size_changed.connect(_reflow)
	refresh()

func _build_columns() -> void:
	var width := int(get_viewport_rect().size.x)
	var count := int(ceil(float(width) / _tile_px))
	for i in count:
		var spr := Sprite2D.new()
		spr.centered = false
		spr.visible = false
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
		var zone = sim.slots[i] if i < sim.slots.size() else null
		if zone == null:
			spr.visible = false  # empty/locked — BuildOverlay shows the lot
			_built_state[i] = null
			continue
		spr.visible = true
		spr.texture = CityTiles.get_tile(ZONE_TILE[zone])
		spr.modulate = ZONE_TINT[zone]
		if _built_state[i] != zone:
			_animate_build(spr, i)
		else:
			spr.scale = Vector2(PIXEL_SCALE, PIXEL_SCALE)
			spr.position = Vector2(i * _tile_px, _baseline - _tile_px)
		_built_state[i] = zone

func _animate_build(spr: Sprite2D, column: int) -> void:
	spr.scale = Vector2(PIXEL_SCALE, 0.0)
	spr.position = Vector2(column * _tile_px, _baseline)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(spr, "scale:y", float(PIXEL_SCALE), _GROW_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "position:y", _baseline - _tile_px, _GROW_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
