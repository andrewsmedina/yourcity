class_name CitySim
extends RefCounted

## Pure city simulation — no engine, scene or rendering dependencies, so it can
## be advanced deterministically and unit-tested in isolation. The view layer
## reads this simulation; the simulation never reads the view.
## (See CLAUDE.md: keep the simulation core decoupled from the view.)

var money: float
var revenue_per_sec: float

func _init(starting_money: float = 1000.0) -> void:
	money = starting_money
	revenue_per_sec = 0.0

## Advance the simulation by `delta` seconds.
func advance(delta: float) -> void:
	money += revenue_per_sec * delta
