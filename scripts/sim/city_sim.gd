class_name CitySim
extends RefCounted

## Pure city simulation — no engine, scene or rendering dependencies, so it can
## be advanced deterministically and unit-tested in isolation. The view layer
## reads this simulation; the simulation never reads the view.
## (See CLAUDE.md: keep the simulation core decoupled from the view.)
##
## The city is a row of build slots that unlock as population grows (#16). Each
## slot is empty or holds one zone. Economic zones move money/population (#13-15)
## and cost monthly upkeep (#17). Five indicators (#19) decay over time (#23),
## are propped up by their matching service zone (#24), and energy drains faster
## the bigger the city (#22). Happiness is their average (#20) and steers
## immigration/revenue (#21).

enum Zone {
	RESIDENTIAL, COMMERCIAL, INDUSTRIAL,
	POLICE, SCHOOL, HOSPITAL, ROADS, POWER,
	PARK, BANK, STADIUM,  # gifts — placeable once granted by a milestone
}

## The 8 zones the player builds normally (keys 1-8); gifts are placed separately.
const BUILDABLE_ZONES := [
	Zone.RESIDENTIAL, Zone.COMMERCIAL, Zone.INDUSTRIAL,
	Zone.POLICE, Zone.SCHOOL, Zone.HOSPITAL, Zone.ROADS, Zone.POWER,
]

const ZONE_NAME := {
	Zone.RESIDENTIAL: "Residencial",
	Zone.COMMERCIAL: "Comercial",
	Zone.INDUSTRIAL: "Industrial",
	Zone.POLICE: "Delegacia",
	Zone.SCHOOL: "Escola",
	Zone.HOSPITAL: "Hospital",
	Zone.ROADS: "Vias",
	Zone.POWER: "Usina",
	Zone.PARK: "Parque",
	Zone.BANK: "Banco",
	Zone.STADIUM: "Estádio",
}

enum Indicator { SECURITY, EDUCATION, HEALTH, TRAFFIC, ENERGY }

enum Phase { VILLAGE, SMALL_TOWN, CITY, METROPOLIS }

const PHASE_NAME := {
	Phase.VILLAGE: "Vilarejo",
	Phase.SMALL_TOWN: "Cidade Pequena",
	Phase.CITY: "Cidade Média",
	Phase.METROPOLIS: "Metrópole",
}
# Population at which each phase begins.
const PHASE_POP := {
	Phase.VILLAGE: 0.0,
	Phase.SMALL_TOWN: 500.0,
	Phase.CITY: 5000.0,
	Phase.METROPOLIS: 50000.0,
}

# Gifts: granted at a population milestone, then placed on the map by the player.
# The bonus applies while the gift building stands.
const GIFT_ZONES := [Zone.PARK, Zone.BANK, Zone.STADIUM]
const GIFT_POP := { Zone.PARK: 2000.0, Zone.BANK: 7000.0, Zone.STADIUM: 200000.0 }
const GIFT_HAPPINESS := { Zone.PARK: 5.0, Zone.BANK: 0.0, Zone.STADIUM: 10.0 }
const BANK_TAX_BONUS := 0.25  # +25% tax income while a Bank stands

enum CrisisType { CRIME, EPIDEMIC, DROPOUT, GRIDLOCK, BLACKOUT }

const CRISIS_TYPES := [
	CrisisType.CRIME, CrisisType.EPIDEMIC, CrisisType.DROPOUT,
	CrisisType.GRIDLOCK, CrisisType.BLACKOUT,
]

const INDICATORS := [
	Indicator.SECURITY, Indicator.EDUCATION, Indicator.HEALTH,
	Indicator.TRAFFIC, Indicator.ENERGY,
]

## Service zone that boosts each indicator.
const SERVICE_FOR := {
	Indicator.SECURITY: Zone.POLICE,
	Indicator.EDUCATION: Zone.SCHOOL,
	Indicator.HEALTH: Zone.HOSPITAL,
	Indicator.TRAFFIC: Zone.ROADS,
	Indicator.ENERGY: Zone.POWER,
}

# --- Economy (SimCity-style: cheap zones, costly infra, tax revenue) ---
const RESIDENTIAL_POP := 1.0 / 3.0   # growth rate: +1 resident every 3s
const RESIDENTIAL_CAPACITY := 250.0  # max residents each residential lot holds

# Cheap zones, expensive services/power (mirrors the SimCity SNES price scale).
const ZONE_COST := {
	Zone.RESIDENTIAL: 100.0, Zone.COMMERCIAL: 100.0, Zone.INDUSTRIAL: 100.0,
	Zone.ROADS: 100.0,
	Zone.POLICE: 500.0, Zone.SCHOOL: 500.0, Zone.HOSPITAL: 500.0,
	Zone.POWER: 3000.0,
	Zone.PARK: 0.0, Zone.BANK: 0.0, Zone.STADIUM: 0.0,  # gifts are free
}
const ZONE_UPKEEP := {  # ongoing cost/sec — services & infra; plain zones are free
	Zone.RESIDENTIAL: 0.0, Zone.COMMERCIAL: 0.0, Zone.INDUSTRIAL: 0.0,
	Zone.ROADS: 0.5,
	Zone.POLICE: 1.0, Zone.SCHOOL: 1.0, Zone.HOSPITAL: 1.0,
	Zone.POWER: 2.0,
	Zone.PARK: 0.0, Zone.BANK: 0.0, Zone.STADIUM: 0.0,
}

# Tax is the main revenue: rate x (residents + businesses). High tax earns more
# but lowers happiness; low tax raises it (the SimCity trade-off).
const TAX_PER_RESIDENT := 0.1
const TAX_PER_BUSINESS := 5.0
const TAX_MIN := 0.0
const TAX_MAX := 0.20
const TAX_STEP := 0.01
const TAX_COMFORT := 0.07
const TAX_HAPPINESS := 150.0  # happiness shift per 100% tax away from comfort
const DEMOLISH_COST := 10.0   # bulldozer cost per lot
const MONTH := 10.0  # seconds per in-game month (calendar only)
const YEAR := MONTH * 12.0  # 120s per in-game year

# Build grid: 30 columns x 3 rows. Starts with one row unlocked; the rest open
# up as population grows.
const GRID_COLS := 45
const GRID_ROWS := 15
const MAX_SLOTS := GRID_COLS * GRID_ROWS  # 675
const BASE_SLOTS := MAX_SLOTS  # whole grid buildable from the start
const POP_PER_SLOT := 50.0

# Which phase unlocks each zone (#39). Basics from the start; the rest as the
# city grows.
const ZONE_UNLOCK_PHASE := {
	Zone.RESIDENTIAL: Phase.VILLAGE,
	Zone.COMMERCIAL: Phase.VILLAGE,
	Zone.ROADS: Phase.VILLAGE,
	Zone.POWER: Phase.VILLAGE,
	Zone.INDUSTRIAL: Phase.VILLAGE,
	Zone.POLICE: Phase.VILLAGE,
	Zone.SCHOOL: Phase.VILLAGE,
	Zone.HOSPITAL: Phase.VILLAGE,
	Zone.PARK: Phase.VILLAGE,
	Zone.BANK: Phase.VILLAGE,
	Zone.STADIUM: Phase.VILLAGE,
}

# --- Indicators ---
const INDICATOR_START := 60.0  # a fresh city starts stable
# Indicators follow supply vs demand (no decay by time): supply comes from the
# matching service; demand for people-services (security/education/health) grows
# with POPULATION, while traffic/energy demand grows with the building count.
const SERVICE_BOOST := 0.5             # indicator supply per matching service
# Residents that one people-service covers (demand per resident = BOOST / this).
const RESIDENTS_PER_SERVICE := {
	Indicator.SECURITY: 1750.0,
	Indicator.EDUCATION: 1500.0,
	Indicator.HEALTH: 2500.0,
}
const DEMAND_PER_BUILDING := 0.03      # traffic demand per built lot (~1 Vias / 16)
const ENERGY_DEMAND_PER_BUILDING := 0.01  # energy demand per built lot (~1 Usina / 50)

# --- Happiness thresholds ---
const HAPPY_HIGH := 70.0
const HAPPY_LOW := 40.0

# --- Crises (#26-#31) ---
# A crisis starts when its indicator drops below CRISIS_THRESHOLD and clears
# once it recovers to CRISIS_RECOVERY (hysteresis avoids flicker). There is no
# hard fail: while active a crisis applies a gradual consequence. RESPONSE_WINDOW
# is just the urgency timer — responding stays possible after it elapses.
const CRISIS_THRESHOLD := 30.0
const CRISIS_RECOVERY := 40.0
const RESPONSE_WINDOW := 60.0

const CRISIS_INDICATOR := {
	CrisisType.CRIME: Indicator.SECURITY,
	CrisisType.EPIDEMIC: Indicator.HEALTH,
	CrisisType.DROPOUT: Indicator.EDUCATION,
	CrisisType.GRIDLOCK: Indicator.TRAFFIC,
	CrisisType.BLACKOUT: Indicator.ENERGY,
}
const CRISIS_TITLE := {
	CrisisType.CRIME: "Onda de Crimes",
	CrisisType.EPIDEMIC: "Epidemia",
	CrisisType.DROPOUT: "Evasão Escolar",
	CrisisType.GRIDLOCK: "Engarrafamento",
	CrisisType.BLACKOUT: "Apagão",
}
# 2-3 response options per crisis: cheap small bump vs expensive big fix.
const CRISIS_RESPONSES := {
	CrisisType.CRIME: [
		{"label": "Construir delegacia", "cost": 5000.0, "bump": 40.0},
		{"label": "Instalar câmeras", "cost": 2000.0, "bump": 25.0},
		{"label": "Contratar policiais", "cost": 1000.0, "bump": 15.0},
	],
	CrisisType.EPIDEMIC: [
		{"label": "Construir hospital", "cost": 5000.0, "bump": 40.0},
		{"label": "Campanha de vacinação", "cost": 2000.0, "bump": 25.0},
		{"label": "Contratar médicos", "cost": 1000.0, "bump": 15.0},
	],
	CrisisType.DROPOUT: [
		{"label": "Construir escola", "cost": 5000.0, "bump": 40.0},
		{"label": "Bolsas de estudo", "cost": 2000.0, "bump": 25.0},
		{"label": "Contratar professores", "cost": 1000.0, "bump": 15.0},
	],
	CrisisType.GRIDLOCK: [
		{"label": "Expandir vias", "cost": 5000.0, "bump": 40.0},
		{"label": "Transporte público", "cost": 2000.0, "bump": 25.0},
		{"label": "Sincronizar semáforos", "cost": 1000.0, "bump": 15.0},
	],
	CrisisType.BLACKOUT: [
		{"label": "Construir usina", "cost": 5000.0, "bump": 40.0},
		{"label": "Comprar energia", "cost": 2000.0, "bump": 25.0},
		{"label": "Racionar consumo", "cost": 1000.0, "bump": 15.0},
	],
}

var money: float
var population: float
var elapsed: float  # seconds the city has been running, for its age/calendar
var tax_rate := 0.07
var upkeep_per_sec: float
var pop_per_sec: float
var indicators := {}  # Indicator -> float (0..100)

# Annual budget: tax and upkeep accrue during the year and are settled in one
# lump sum when the year turns over (last_year_* hold the most recent report).
var _year_tax := 0.0
var _year_upkeep := 0.0
var _last_year := 1
var last_year_tax := 0.0
var last_year_upkeep := 0.0

var slots: Array = []  # each entry is a Zone value, or null when empty
var gift_granted := {}    # gift Zone -> true once its milestone has been reached
var gift_available := {}  # gift Zone -> true while granted but not yet placed

var _crisis_elapsed := {}  # CrisisType -> seconds active (key present iff active)

func _init(starting_money: float = 20000.0) -> void:
	money = starting_money
	population = 0.0
	elapsed = 0.0
	_last_year = 1
	for ind in INDICATORS:
		indicators[ind] = INDICATOR_START
	_sync_slots()
	_recompute_rates()

## Number of slots currently available to build on (capped at the grid size).
func unlocked_slots() -> int:
	return mini(MAX_SLOTS, BASE_SLOTS + int(population / POP_PER_SLOT))

## Current city phase, derived from population (#38).
func phase() -> Phase:
	if population >= PHASE_POP[Phase.METROPOLIS]:
		return Phase.METROPOLIS
	if population >= PHASE_POP[Phase.CITY]:
		return Phase.CITY
	if population >= PHASE_POP[Phase.SMALL_TOWN]:
		return Phase.SMALL_TOWN
	return Phase.VILLAGE

## Whether a zone is unlocked at the current phase (#39).
func is_zone_unlocked(zone: Zone) -> bool:
	return int(phase()) >= int(ZONE_UNLOCK_PHASE[zone])

func is_gift(zone: Zone) -> bool:
	return GIFT_ZONES.has(zone)

func can_build(zone: Zone, slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size() or slots[slot_index] != null:
		return false
	if is_gift(zone):
		return gift_available.has(zone)  # free, only if granted and not placed
	return is_zone_unlocked(zone) and money >= ZONE_COST[zone]

## Build a zone into an empty unlocked slot. Returns false (no-op) if the slot
## is taken/locked or there isn't enough money.
func build(zone: Zone, slot_index: int) -> bool:
	if not can_build(zone, slot_index):
		return false
	if is_gift(zone):
		gift_available.erase(zone)  # gift consumed (placed)
	else:
		money -= ZONE_COST[zone]
	slots[slot_index] = zone
	_recompute_rates()
	return true

## Remove whatever is on a lot (the bulldozer); costs DEMOLISH_COST. Returns
## false if the lot was empty.
func demolish(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size() or slots[slot_index] == null:
		return false
	money = maxf(0.0, money - DEMOLISH_COST)
	slots[slot_index] = null
	_recompute_rates()
	return true

func zone_count(zone: Zone) -> int:
	var n := 0
	for s in slots:
		if s == zone:
			n += 1
	return n

## Total built lots — the demand driver for every indicator.
func building_count() -> int:
	var n := 0
	for s in slots:
		if s != null:
			n += 1
	return n

## Maximum residents the city can house (sum of residential lot capacities).
func housing_capacity() -> float:
	return zone_count(Zone.RESIDENTIAL) * RESIDENTIAL_CAPACITY

## Average of the five indicators, shifted by how the tax rate sits relative to
## the comfortable level (#20).
func happiness() -> float:
	var total := 0.0
	for ind in INDICATORS:
		total += indicators[ind]
	var base := total / INDICATORS.size()
	return clampf(base + (TAX_COMFORT - tax_rate) * TAX_HAPPINESS + _gift_happiness(), 0.0, 100.0)

## Whether a gift building currently stands in the city (its bonus is active).
func has_gift(gift: Zone) -> bool:
	return zone_count(gift) > 0

func _gift_happiness() -> float:
	var bonus := 0.0
	for g in GIFT_ZONES:
		if has_gift(g):
			bonus += GIFT_HAPPINESS[g]
	return bonus

## Tax revenue per second at the current rate (residents + businesses).
func tax_income() -> float:
	var businesses := zone_count(Zone.COMMERCIAL) + zone_count(Zone.INDUSTRIAL)
	var income := (population * TAX_PER_RESIDENT + businesses * TAX_PER_BUSINESS) * tax_rate
	if has_gift(Zone.BANK):
		income *= 1.0 + BANK_TAX_BONUS
	return income

func net_per_sec() -> float:
	return tax_income() - upkeep_per_sec

## Nudge the tax rate (clamped); the player controls this.
func adjust_tax(delta: float) -> void:
	tax_rate = clampf(tax_rate + delta, TAX_MIN, TAX_MAX)

## City age in whole years (starts at Year 1).
func year() -> int:
	return int(elapsed / YEAR) + 1

## Current month within the year (1-12).
func month() -> int:
	return int(elapsed / MONTH) % 12 + 1

## Advance the simulation by `delta` seconds.
func advance(delta: float) -> void:
	elapsed += delta
	# Tax and upkeep accrue through the year; settled as a lump sum at year-end.
	_year_tax += tax_income() * delta
	_year_upkeep += upkeep_per_sec * delta
	if year() != _last_year:
		_last_year = year()
		_settle_year()
	# Population grows toward housing capacity (and leaves when unhappy).
	population = clampf(population + pop_per_sec * _pop_factor() * delta, 0.0, housing_capacity())
	for ind in INDICATORS:
		indicators[ind] = clampf(indicators[ind] + indicator_rate(ind) * delta, 0.0, 100.0)
	_update_crises(delta)  # crises spend money immediately, not via the budget
	_check_gifts()
	money = maxf(0.0, money)  # no bottomless debt — keeps the city recoverable
	_sync_slots()

func _check_gifts() -> void:
	for gift in GIFT_ZONES:
		if not gift_granted.has(gift) and population >= GIFT_POP[gift]:
			gift_granted[gift] = true
			gift_available[gift] = true  # ready for the player to place

func _settle_year() -> void:
	last_year_tax = _year_tax
	last_year_upkeep = _year_upkeep
	money += _year_tax - _year_upkeep
	_year_tax = 0.0
	_year_upkeep = 0.0

# --- Crises ---

func active_crises() -> Array:
	return _crisis_elapsed.keys()

func is_crisis_active(crisis: CrisisType) -> bool:
	return _crisis_elapsed.has(crisis)

func crisis_elapsed(crisis: CrisisType) -> float:
	return _crisis_elapsed.get(crisis, 0.0)

## Seconds left in the urgency window (0 once it elapses; response still works).
func crisis_time_left(crisis: CrisisType) -> float:
	return maxf(0.0, RESPONSE_WINDOW - crisis_elapsed(crisis))

func responses_for(crisis: CrisisType) -> Array:
	return CRISIS_RESPONSES[crisis]

## Pay for and apply a crisis response. Returns false (no-op) if the crisis
## isn't active, the index is invalid, or there isn't enough money.
func respond(crisis: CrisisType, response_index: int) -> bool:
	if not _crisis_elapsed.has(crisis):
		return false
	var responses: Array = CRISIS_RESPONSES[crisis]
	if response_index < 0 or response_index >= responses.size():
		return false
	var option: Dictionary = responses[response_index]
	if money < option.cost:
		return false
	money -= option.cost
	var ind: Indicator = CRISIS_INDICATOR[crisis]
	indicators[ind] = clampf(indicators[ind] + option.bump, 0.0, 100.0)
	if indicators[ind] >= CRISIS_RECOVERY:
		_crisis_elapsed.erase(crisis)
	return true

func _update_crises(delta: float) -> void:
	for crisis in CRISIS_TYPES:
		var value: float = indicators[CRISIS_INDICATOR[crisis]]
		if _crisis_elapsed.has(crisis):
			if value >= CRISIS_RECOVERY:
				_crisis_elapsed.erase(crisis)
			else:
				_crisis_elapsed[crisis] += delta
				_apply_consequence(crisis, delta)
		elif value < CRISIS_THRESHOLD:
			_crisis_elapsed[crisis] = 0.0  # crisis begins

# Gradual consequence of an ignored crisis — never an instant fail (#30).
func _apply_consequence(crisis: CrisisType, delta: float) -> void:
	match crisis:
		CrisisType.CRIME:
			population = maxf(0.0, population - 0.2 * delta)
		CrisisType.EPIDEMIC:
			population = maxf(0.0, population - 0.1 * delta)
			money -= 5.0 * delta
		CrisisType.DROPOUT, CrisisType.GRIDLOCK:
			money -= 5.0 * delta
		CrisisType.BLACKOUT:
			for ind in INDICATORS:
				indicators[ind] = maxf(0.0, indicators[ind] - 0.1 * delta)

# --- Serialization (#40, #41) ---

func to_dict() -> Dictionary:
	var inds := []
	for ind in INDICATORS:
		inds.append(indicators[ind])
	var crises := {}
	for crisis in _crisis_elapsed:
		crises[str(crisis)] = _crisis_elapsed[crisis]
	return {
		"money": money,
		"population": population,
		"elapsed": elapsed,
		"tax_rate": tax_rate,
		"year_tax": _year_tax,
		"year_upkeep": _year_upkeep,
		"slots": slots.duplicate(),
		"indicators": inds,
		"crises": crises,
		"gift_granted": gift_granted.keys(),
		"gift_available": gift_available.keys(),
	}

func from_dict(data: Dictionary) -> void:
	money = float(data.get("money", money))
	population = float(data.get("population", population))
	elapsed = float(data.get("elapsed", elapsed))
	tax_rate = clampf(float(data.get("tax_rate", tax_rate)), TAX_MIN, TAX_MAX)
	_year_tax = float(data.get("year_tax", 0.0))
	_year_upkeep = float(data.get("year_upkeep", 0.0))
	var saved_slots = data.get("slots", null)
	if saved_slots != null:
		slots = []
		for v in saved_slots:
			slots.append(null if v == null else int(v))
	var inds = data.get("indicators", null)
	if inds != null:
		for i in INDICATORS.size():
			if i < inds.size():
				indicators[INDICATORS[i]] = float(inds[i])
	_crisis_elapsed = {}
	for key in data.get("crises", {}):
		_crisis_elapsed[int(key)] = float(data["crises"][key])
	gift_granted = {}
	for g in data.get("gift_granted", []):
		gift_granted[int(g)] = true
	gift_available = {}
	for g in data.get("gift_available", []):
		gift_available[int(g)] = true
	_last_year = year()
	_sync_slots()
	_recompute_rates()

# --- internals ---

func _sync_slots() -> void:
	while slots.size() < unlocked_slots():
		slots.append(null)

func _recompute_rates() -> void:
	pop_per_sec = zone_count(Zone.RESIDENTIAL) * RESIDENTIAL_POP
	var upkeep := 0.0
	for s in slots:
		if s != null:
			upkeep += ZONE_UPKEEP[s]
	upkeep_per_sec = upkeep

## Net rate of change for an indicator (supply from services minus city demand).
## Positive = recovering, negative = falling.
func indicator_rate(ind: Indicator) -> float:
	var supply := zone_count(SERVICE_FOR[ind]) * SERVICE_BOOST
	var demand := 0.0
	match ind:
		Indicator.SECURITY, Indicator.EDUCATION, Indicator.HEALTH:
			demand = population * SERVICE_BOOST / RESIDENTS_PER_SERVICE[ind]
		Indicator.TRAFFIC:
			demand = building_count() * DEMAND_PER_BUILDING
		Indicator.ENERGY:
			demand = _energy_consumers() * ENERGY_DEMAND_PER_BUILDING
	return supply - demand

## Buildings that draw power — everything except roads and the power plants.
func _energy_consumers() -> int:
	var n := 0
	for s in slots:
		if s != null and s != Zone.ROADS and s != Zone.POWER:
			n += 1
	return n

func _pop_factor() -> float:
	var h := happiness()
	if h >= HAPPY_HIGH:
		return 1.5   # immigration
	if h < HAPPY_LOW:
		return -1.0  # emigration
	return 1.0
