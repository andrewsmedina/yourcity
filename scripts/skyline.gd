extends Node2D

## Procedural city skyline rendered along the bottom of the taskbar window
## (issue #10). Fills the available width with building tiles at an integer
## scale (crisp pixels) and animates buildings rising into place as the city
## grows. Day/night tint is issue #11; per-building construction polish is #12.

const PIXEL_SCALE := 3
const BUILDING_TILES := ["house", "building_low", "building_mid", "building_high"]

@export var building_count := 0

var _columns: Array[Sprite2D] = []
var _tile_px := 0

func _ready() -> void:
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	_build_columns()
	set_building_count(building_count)

func _build_columns() -> void:
	var width := int(get_viewport_rect().size.x)
	var count := int(ceil(float(width) / _tile_px))
	var baseline := int(get_viewport_rect().size.y)
	for i in count:
		var spr := Sprite2D.new()
		spr.centered = false
		spr.scale = Vector2(PIXEL_SCALE, PIXEL_SCALE)
		spr.position = Vector2(i * _tile_px, baseline)  # off-screen below until grown
		spr.texture = CityTiles.get_tile(_pick_tile(i))
		add_child(spr)
		_columns.append(spr)

func _pick_tile(column: int) -> String:
	# Deterministic per column so the skyline is stable between frames.
	return BUILDING_TILES[(column * 7 + 3) % BUILDING_TILES.size()]

## Reveal the first `n` buildings (clamped), animating any newly revealed ones
## up from the baseline.
func set_building_count(n: int) -> void:
	building_count = clamp(n, 0, _columns.size())
	var baseline := get_viewport_rect().size.y
	for i in _columns.size():
		var spr := _columns[i]
		var raised := i < building_count
		var target_y := baseline - _tile_px if raised else baseline
		var tween := create_tween()
		tween.tween_property(spr, "position:y", target_y, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func capacity() -> int:
	return _columns.size()
