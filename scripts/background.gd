extends Control

## Tiled background that fills the whole window with the 8x8 ground tiles,
## picking one of the three per cell with a stable per-cell hash (so it doesn't
## flicker). Sits on a CanvasLayer behind everything; mouse-transparent.

const SRC := 8      # source tile size in px
const SCALE := 4    # drawn size = 32px

var _tiles: Array[Texture2D] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tiles = [
		load("res://assets/tile_0000.png"),
		load("res://assets/tile_0001.png"),
		load("res://assets/tile_0002.png"),
	]
	resized.connect(queue_redraw)

func _process(_delta: float) -> void:
	queue_redraw()  # follow the real window size, which can differ from `size`

func _draw() -> void:
	if _tiles.is_empty():
		return
	var t := SRC * SCALE
	# Cover the larger of the control size and the actual window, with overdraw,
	# so there are never gaps regardless of macOS window-size quirks.
	var win := Vector2(DisplayServer.window_get_size())
	var w: float = maxf(size.x, win.x)
	var h: float = maxf(size.y, win.y)
	var cols := int(ceil(w / t)) + 2
	var rows := int(ceil(h / t)) + 2
	for r in rows:
		for c in cols:
			var idx: int = abs(hash(Vector2i(c, r))) % _tiles.size()
			draw_texture_rect(_tiles[idx], Rect2(c * t, r * t, t, t), false)
