extends CanvasModulate

## Day/night cycle (issue #11). Tints the whole 2D scene via CanvasModulate,
## driven by a city clock that loops every DAY_LENGTH seconds. Other systems can
## read time_of_day (0.0 = midnight, 0.5 = noon) for the city clock UI later.

## Full day length in seconds. Short by default so the cycle is visible while
## developing; the real game will slow this down.
const DAY_LENGTH := 60.0

var time_of_day := 0.25  # start mid-morning

var _gradient := Gradient.new()

func _ready() -> void:
	# Color of the ambient light across the day. Offsets are fractions of a day.
	_gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	# Kept bright enough that the city stays readable even at night.
	_gradient.colors = PackedColorArray([
		Color(0.55, 0.58, 0.75),  # midnight — dim cool blue
		Color(0.95, 0.85, 0.70),  # dawn — warm
		Color(1.0, 1.0, 1.0),     # noon — full daylight
		Color(0.95, 0.70, 0.55),  # dusk — orange
		Color(0.55, 0.58, 0.75),  # back to midnight
	])
	_apply()

func _process(delta: float) -> void:
	time_of_day = fmod(time_of_day + delta / DAY_LENGTH, 1.0)
	_apply()

func _apply() -> void:
	color = _gradient.sample(time_of_day)

func is_night() -> bool:
	return time_of_day < 0.2 or time_of_day > 0.8
