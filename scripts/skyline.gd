extends Node2D

## Procedural city skyline rendered along the bottom of the taskbar window
## (issue #10), with buildings that animate up from the ground as they are
## constructed (issue #12). Tiles render at an integer scale for crisp pixels.
## Day/night tint is handled separately by DayNight (#11).

const PIXEL_SCALE := 3
const BUILDING_TILES := ["house", "building_low", "building_mid", "building_high"]
const _GROW_TIME := 0.35

@export var building_count := 0

var _columns: Array[Sprite2D] = []
var _tile_px := 0
var _baseline := 0.0
var _shown := 0

func _ready() -> void:
	_tile_px = CityTiles.TILE * PIXEL_SCALE
	_baseline = get_viewport_rect().size.y
	_build_columns()
	var initial := building_count
	building_count = 0
	set_building_count(initial)

func _build_columns() -> void:
	var width := int(get_viewport_rect().size.x)
	var count := int(ceil(float(width) / _tile_px))
	for i in count:
		var spr := Sprite2D.new()
		spr.centered = false
		spr.texture = CityTiles.get_tile(_pick_tile(i))
		spr.scale = Vector2(PIXEL_SCALE, 0.0)          # start flat — not built yet
		spr.position = Vector2(i * _tile_px, _baseline) # anchored to the ground
		add_child(spr)
		_columns.append(spr)

func _pick_tile(column: int) -> String:
	# Deterministic per column so the skyline is stable between frames.
	return BUILDING_TILES[(column * 7 + 3) % BUILDING_TILES.size()]

## Reveal the first `n` buildings (clamped). Newly added ones animate up from
## the ground; removed ones collapse back down. Stable buildings are untouched.
func set_building_count(n: int) -> void:
	n = clamp(n, 0, _columns.size())
	if n > _shown:
		for i in range(_shown, n):
			_construct(_columns[i])
	elif n < _shown:
		for i in range(n, _shown):
			_demolish(_columns[i])
	_shown = n
	building_count = n

func _construct(spr: Sprite2D) -> void:
	# Grow vertical scale 0 -> full while raising the top, keeping the base on
	# the ground, so the building reads as rising out of the lot.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(spr, "scale:y", float(PIXEL_SCALE), _GROW_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(spr, "position:y", _baseline - _tile_px, _GROW_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _demolish(spr: Sprite2D) -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(spr, "scale:y", 0.0, _GROW_TIME * 0.7).set_ease(Tween.EASE_IN)
	tween.tween_property(spr, "position:y", _baseline, _GROW_TIME * 0.7).set_ease(Tween.EASE_IN)

func capacity() -> int:
	return _columns.size()
