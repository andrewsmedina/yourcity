class_name CitySim
extends RefCounted

## Pure city simulation — no engine, scene or rendering dependencies, so it can
## be advanced deterministically and unit-tested in isolation. The view layer
## reads this simulation; the simulation never reads the view.
## (See CLAUDE.md: keep the simulation core decoupled from the view.)

enum Zone { RESIDENTIAL, COMMERCIAL, INDUSTRIAL, SERVICE }

# Per-zone, per-second passive contributions (provisional — see GDD balancing).
# Commercial and industrial generate money; residential grows population.
# Service zones earn nothing here — their value is propping up indicators, and
# their upkeep cost lands with the fixed monthly costs (issue #17).
const COMMERCIAL_REVENUE := 2.0
const INDUSTRIAL_REVENUE := 1.5
const RESIDENTIAL_POP := 1.0 / 3.0  # +1 resident every 3s

var money: float
var population: float
var revenue_per_sec: float
var pop_per_sec: float

var _zone_counts := [0, 0, 0, 0]

func _init(starting_money: float = 1000.0) -> void:
	money = starting_money
	population = 0.0
	_recompute_rates()

## Add (or remove, with a negative amount) zones of a type and refresh rates.
func add_zone(zone: Zone, amount: int = 1) -> void:
	_zone_counts[zone] = max(0, _zone_counts[zone] + amount)
	_recompute_rates()

func zone_count(zone: Zone) -> int:
	return _zone_counts[zone]

## Advance the simulation by `delta` seconds.
func advance(delta: float) -> void:
	money += revenue_per_sec * delta
	population += pop_per_sec * delta

func _recompute_rates() -> void:
	revenue_per_sec = _zone_counts[Zone.COMMERCIAL] * COMMERCIAL_REVENUE \
		+ _zone_counts[Zone.INDUSTRIAL] * INDUSTRIAL_REVENUE
	pop_per_sec = _zone_counts[Zone.RESIDENTIAL] * RESIDENTIAL_POP
