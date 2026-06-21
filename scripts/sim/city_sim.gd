class_name CitySim
extends RefCounted

## Pure city simulation — no engine, scene or rendering dependencies, so it can
## be advanced deterministically and unit-tested in isolation. The view layer
## reads this simulation; the simulation never reads the view.
## (See CLAUDE.md: keep the simulation core decoupled from the view.)
##
## The city is a row of build slots. Slots unlock as population grows (#16);
## each slot is empty or holds one zone. Commercial/industrial zones earn money,
## residential grows population, and every built zone has monthly upkeep (#17).

enum Zone { RESIDENTIAL, COMMERCIAL, INDUSTRIAL, SERVICE }

# Per-zone, per-second passive contributions (provisional — see GDD balancing).
const COMMERCIAL_REVENUE := 2.0
const INDUSTRIAL_REVENUE := 1.5
const RESIDENTIAL_POP := 1.0 / 3.0  # +1 resident every 3s

# Build cost per zone (GDD).
const ZONE_COST := {
	Zone.RESIDENTIAL: 500.0,
	Zone.COMMERCIAL: 800.0,
	Zone.INDUSTRIAL: 1000.0,
	Zone.SERVICE: 1500.0,
}

# Upkeep per zone per in-game month — salaries/maintenance (#17). Charged
# continuously at ZONE_UPKEEP / MONTH per second. Services cost the most.
const ZONE_UPKEEP := {
	Zone.RESIDENTIAL: 10.0,
	Zone.COMMERCIAL: 20.0,
	Zone.INDUSTRIAL: 40.0,
	Zone.SERVICE: 80.0,
}
const MONTH := 30.0  # seconds per in-game month

# Slot unlocking: start with BASE_SLOTS, +1 every POP_PER_SLOT residents.
const BASE_SLOTS := 4
const POP_PER_SLOT := 100.0

var money: float
var population: float
var revenue_per_sec: float
var upkeep_per_sec: float
var pop_per_sec: float

var slots: Array = []  # each entry is a Zone value, or null when empty

func _init(starting_money: float = 1000.0) -> void:
	money = starting_money
	population = 0.0
	_sync_slots()
	_recompute_rates()

## Number of slots currently available to build on.
func unlocked_slots() -> int:
	return BASE_SLOTS + int(population / POP_PER_SLOT)

func can_build(zone: Zone, slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < slots.size() \
		and slots[slot_index] == null \
		and money >= ZONE_COST[zone]

## Build a zone into an empty unlocked slot. Returns false (no-op) if the slot
## is taken/locked or there isn't enough money.
func build(zone: Zone, slot_index: int) -> bool:
	if not can_build(zone, slot_index):
		return false
	money -= ZONE_COST[zone]
	slots[slot_index] = zone
	_recompute_rates()
	return true

func zone_count(zone: Zone) -> int:
	var n := 0
	for s in slots:
		if s == zone:
			n += 1
	return n

func net_per_sec() -> float:
	return revenue_per_sec - upkeep_per_sec

## Advance the simulation by `delta` seconds.
func advance(delta: float) -> void:
	money += net_per_sec() * delta
	population += pop_per_sec * delta
	_sync_slots()

func _sync_slots() -> void:
	while slots.size() < unlocked_slots():
		slots.append(null)

func _recompute_rates() -> void:
	revenue_per_sec = zone_count(Zone.COMMERCIAL) * COMMERCIAL_REVENUE \
		+ zone_count(Zone.INDUSTRIAL) * INDUSTRIAL_REVENUE
	pop_per_sec = zone_count(Zone.RESIDENTIAL) * RESIDENTIAL_POP
	var upkeep := 0.0
	for s in slots:
		if s != null:
			upkeep += ZONE_UPKEEP[s]
	upkeep_per_sec = upkeep / MONTH
