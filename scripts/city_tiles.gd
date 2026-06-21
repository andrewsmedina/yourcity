extends Node

## Slices the city spritesheet into per-tile textures addressable by name, so
## the rest of the game asks for "building_high" instead of juggling pixel
## regions (issue #9).
##
## The art in assets/city_spritesheet.png is a PLACEHOLDER — replace it with
## real pixel art, keeping TILE size and NAMES order in sync with
## tools/gen_placeholder_spritesheet.py.

const TILE := 16
const SHEET := preload("res://assets/city_spritesheet.png")
const NAMES := ["ground", "road", "tree", "house",
	"building_low", "building_mid", "building_high", "park"]

var _tiles: Dictionary = {}

func _ready() -> void:
	for i in NAMES.size():
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET
		atlas.region = Rect2(i * TILE, 0, TILE, TILE)
		_tiles[NAMES[i]] = atlas

func get_tile(tile_name: String) -> AtlasTexture:
	return _tiles.get(tile_name)

func tile_names() -> Array:
	return NAMES.duplicate()
