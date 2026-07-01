extends SceneTree

## Headless test runner for the pure simulation classes.
## Run with: godot --headless --script tests/run_tests.gd
## Exits non-zero if any check fails (CI-friendly).

var _failures := 0

func _initialize() -> void:
	_test_build_deducts_cost_and_occupies_slot()
	_test_cannot_build_on_occupied_slot()
	_test_cannot_build_without_money()
	_test_cannot_build_locked_slot()
	_test_tax_income_from_residents_and_business()
	_test_tax_rate_shifts_happiness()
	_test_residential_zone_grows_population()
	_test_upkeep_charged_monthly()
	_test_tax_collected_yearly_not_continuously()
	_test_grid_starts_full()
	_test_demolish_clears_lot()
	_test_gifts_granted_placed_and_bonus()
	_test_indicators_start_at_default()
	_test_happiness_is_average_of_indicators()
	_test_indicators_react_to_demand()
	_test_service_boosts_its_indicator()
	_test_connectivity_makes_buildings_functional()
	_test_high_happiness_boosts_population()
	_test_low_happiness_causes_emigration()
	_test_crisis_starts_below_threshold()
	_test_no_crisis_above_threshold()
	_test_crisis_clears_on_recovery()
	_test_response_bumps_indicator_and_costs()
	_test_cannot_respond_without_money()
	_test_ignored_crime_reduces_population()
	_test_population_capped_by_housing()
	_test_city_ages_in_years()
	_test_phase_tracks_population()
	_test_all_zones_unlocked_from_start()
	_test_save_load_round_trip()

	if _failures > 0:
		push_error("%d test(s) failed" % _failures)
		quit(1)
	else:
		print("all tests passed")
		quit(0)

func _test_build_deducts_cost_and_occupies_slot() -> void:
	var c := CitySim.new(1000.0)
	var ok := c.build(CitySim.Zone.COMMERCIAL, 0)
	_expect("build occupies slot and deducts cost",
		ok and c.slots[0] == CitySim.Zone.COMMERCIAL
		and is_equal_approx(c.money, 1000.0 - CitySim.ZONE_COST[CitySim.Zone.COMMERCIAL]))

func _test_cannot_build_on_occupied_slot() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.COMMERCIAL, 0)
	var ok := c.build(CitySim.Zone.INDUSTRIAL, 0)
	_expect("cannot build on an occupied slot", not ok and c.slots[0] == CitySim.Zone.COMMERCIAL)

func _test_cannot_build_without_money() -> void:
	var c := CitySim.new(100.0)
	var ok := c.build(CitySim.Zone.POLICE, 0)  # costs 1500
	_expect("cannot build without enough money", not ok and c.slots[0] == null)

func _test_cannot_build_locked_slot() -> void:
	var c := CitySim.new(100000.0)
	var locked := c.unlocked_slots()  # first locked index
	var ok := c.build(CitySim.Zone.COMMERCIAL, locked)
	_expect("cannot build on a locked slot", not ok)

func _test_tax_income_from_residents_and_business() -> void:
	var c := CitySim.new(100000.0)
	_wire_row(c, [CitySim.Zone.COMMERCIAL], CitySim.GRID_COLS)  # 1 functional business
	c.population = 100.0
	var expected := (100.0 * CitySim.TAX_PER_RESIDENT + 1.0 * CitySim.TAX_PER_BUSINESS) * c.tax_rate
	_expect("tax income from residents and businesses", is_equal_approx(c.tax_income(), expected))

func _test_tax_rate_shifts_happiness() -> void:
	var c := CitySim.new()
	var at_comfort := c.happiness()  # tax starts at comfort
	c.tax_rate = CitySim.TAX_COMFORT + 0.10
	var high := c.happiness()
	c.tax_rate = 0.0
	var low := c.happiness()
	_expect("high tax lowers happiness, low tax raises it",
		high < at_comfort and low > at_comfort)

func _test_residential_zone_grows_population() -> void:
	var c := CitySim.new(100000.0)
	_wire_row(c, [CitySim.Zone.RESIDENTIAL, CitySim.Zone.RESIDENTIAL, CitySim.Zone.RESIDENTIAL],
		CitySim.GRID_COLS)  # 3 functional -> 1 pop/sec
	c.advance(2.0)
	_expect("residential zones grow population", is_equal_approx(c.population, 2.0))

func _test_upkeep_charged_monthly() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.POLICE, 0)
	_expect("upkeep is the per-second cost",
		is_equal_approx(c.upkeep_per_sec, CitySim.ZONE_UPKEEP[CitySim.Zone.POLICE]))

func _test_tax_collected_yearly_not_continuously() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.RESIDENTIAL, 0)
	c.build(CitySim.Zone.COMMERCIAL, 1)
	c.population = 250.0
	var start := c.money
	c.advance(CitySim.YEAR - 1.0)  # almost a year — nothing collected yet
	var mid_unchanged := is_equal_approx(c.money, start)
	c.advance(2.0)  # crosses the year boundary — lump-sum settlement
	var collected := c.money > start
	_expect("tax is collected yearly, not continuously", mid_unchanged and collected)

func _test_gifts_granted_placed_and_bonus() -> void:
	var c := CitySim.new(100000.0)
	var need := int(ceil(CitySim.GIFT_POP[CitySim.Zone.PARK] / CitySim.RESIDENTIAL_CAPACITY))
	var res: Array = []
	for i in need:
		res.append(CitySim.Zone.RESIDENTIAL)  # functional housing for the milestone
	_wire_row(c, res, CitySim.GRID_COLS)
	c.population = CitySim.GIFT_POP[CitySim.Zone.PARK]
	c.advance(0.1)
	var granted := c.gift_available.has(CitySim.Zone.PARK)  # offered, not yet placed
	var inactive := not c.has_gift(CitySim.Zone.PARK)
	# Place the park next to the powered row (right of the last residential), with a road above.
	var park_slot: int = CitySim.GRID_COLS + 1 + need
	c.build(CitySim.Zone.ROADS, park_slot - CitySim.GRID_COLS)
	var placed := c.build(CitySim.Zone.PARK, park_slot)
	var active := c.has_gift(CitySim.Zone.PARK) and not c.gift_available.has(CitySim.Zone.PARK)
	_expect("gift granted -> placed -> active when functional",
		granted and inactive and placed and active)

func _test_demolish_clears_lot() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.COMMERCIAL, 0)
	var before := c.money
	var ok := c.demolish(0)
	var empty_again := c.demolish(0)  # already empty -> no-op
	_expect("demolish clears the lot and costs, no-op when empty",
		ok and c.slots[0] == null and not empty_again
		and is_equal_approx(c.money, before - CitySim.DEMOLISH_COST))

func _test_grid_starts_full() -> void:
	var c := CitySim.new(10000.0)
	c.advance(0.0)  # triggers slot sync
	_expect("the whole grid is buildable from the start", c.slots.size() == CitySim.MAX_SLOTS)

func _test_indicators_start_at_default() -> void:
	var c := CitySim.new()
	_expect("indicators start at the default",
		is_equal_approx(c.indicators[CitySim.Indicator.SECURITY], CitySim.INDICATOR_START))

func _test_happiness_is_average_of_indicators() -> void:
	var c := CitySim.new()
	c.indicators[CitySim.Indicator.SECURITY] = 100.0
	c.indicators[CitySim.Indicator.EDUCATION] = 0.0
	# Health stays at INDICATOR_START; happiness is the average of the 3.
	var start := CitySim.INDICATOR_START
	var expected := (100.0 + 0.0 + start) / 3.0
	_expect("happiness is the average of indicators", is_equal_approx(c.happiness(), expected))

func _test_indicators_react_to_demand() -> void:
	var empty := CitySim.new(100000.0)
	empty.advance(5.0)
	var stable := is_equal_approx(empty.indicators[CitySim.Indicator.SECURITY], CitySim.INDICATOR_START)
	var c := CitySim.new(100000.0)
	c.population = 2000.0  # people, but no police
	var fell := c.indicator_rate(CitySim.Indicator.SECURITY) < 0.0
	_expect("security stable when empty, falls under population demand", stable and fell)

func _test_service_boosts_its_indicator() -> void:
	var c := CitySim.new(100000.0)
	_wire_row(c, [CitySim.Zone.POLICE], CitySim.GRID_COLS)  # functional police, no residents
	c.advance(1.0)
	# With no population there's no security demand, so it rises by SERVICE_BOOST.
	_expect("a service boosts its indicator",
		is_equal_approx(c.indicators[CitySim.Indicator.SECURITY],
			CitySim.INDICATOR_START + CitySim.SERVICE_BOOST))

func _test_connectivity_makes_buildings_functional() -> void:
	# A lone commercial (no power, no road) is not functional.
	var a := CitySim.new(100000.0)
	a.build(CitySim.Zone.COMMERCIAL, 0)
	var lone := not a.is_functional(0)
	# Commercial next to a power plant (power) and a road becomes functional.
	var b := CitySim.new(100000.0)
	b.build(CitySim.Zone.COMMERCIAL, 1)   # slot 1
	b.build(CitySim.Zone.POWER, 0)        # left neighbor -> conducts power
	b.build(CitySim.Zone.ROADS, 1 + CitySim.GRID_COLS)  # below -> road access
	var wired := b.is_functional(1)
	_expect("buildings need power + road to function", lone and wired)

func _test_high_happiness_boosts_population() -> void:
	var c := CitySim.new(100000.0)
	_wire_row(c, [CitySim.Zone.RESIDENTIAL, CitySim.Zone.RESIDENTIAL, CitySim.Zone.RESIDENTIAL],
		CitySim.GRID_COLS)  # 1 pop/sec base
	for ind in CitySim.INDICATORS:
		c.indicators[ind] = 100.0  # happiness 100 -> immigration
	c.advance(2.0)
	_expect("high happiness boosts population (1.5x)", is_equal_approx(c.population, 3.0))

func _test_low_happiness_causes_emigration() -> void:
	var c := CitySim.new(100000.0)
	_wire_row(c, [CitySim.Zone.RESIDENTIAL, CitySim.Zone.RESIDENTIAL, CitySim.Zone.RESIDENTIAL],
		CitySim.GRID_COLS)  # 1 pop/sec base
	for ind in CitySim.INDICATORS:
		c.indicators[ind] = 10.0  # happiness 10 -> emigration
	c.population = 100.0
	c.advance(2.0)
	_expect("low happiness causes emigration", is_equal_approx(c.population, 98.0))

func _test_crisis_starts_below_threshold() -> void:
	var c := CitySim.new()
	c.indicators[CitySim.Indicator.SECURITY] = 20.0
	c.advance(0.1)
	_expect("crisis starts below threshold", c.is_crisis_active(CitySim.CrisisType.CRIME))

func _test_no_crisis_above_threshold() -> void:
	var c := CitySim.new()
	c.advance(0.1)
	_expect("no crisis while indicators are healthy", c.active_crises().is_empty())

func _test_crisis_clears_on_recovery() -> void:
	var c := CitySim.new()
	c.indicators[CitySim.Indicator.SECURITY] = 20.0
	c.advance(0.1)
	c.indicators[CitySim.Indicator.SECURITY] = 50.0  # back above recovery
	c.advance(0.1)
	_expect("crisis clears on recovery", not c.is_crisis_active(CitySim.CrisisType.CRIME))

func _test_response_bumps_indicator_and_costs() -> void:
	var c := CitySim.new(10000.0)
	c.indicators[CitySim.Indicator.SECURITY] = 20.0
	c.advance(0.1)
	var ok := c.respond(CitySim.CrisisType.CRIME, 2)  # contratar policiais: 1000, +15
	var sec: float = c.indicators[CitySim.Indicator.SECURITY]
	_expect("response costs money and bumps the indicator",
		ok and is_equal_approx(c.money, 9000.0) and sec > 34.0 and sec < 36.0)

func _test_cannot_respond_without_money() -> void:
	var c := CitySim.new(100.0)
	c.indicators[CitySim.Indicator.SECURITY] = 20.0
	c.advance(0.1)
	var ok := c.respond(CitySim.CrisisType.CRIME, 0)  # delegacia: 5000
	_expect("cannot respond without money", not ok and is_equal_approx(c.money, 100.0))

func _test_ignored_crime_reduces_population() -> void:
	var c := CitySim.new()
	c.population = 100.0
	c.indicators[CitySim.Indicator.SECURITY] = 20.0
	c.advance(0.5)  # crisis begins
	c.advance(1.0)  # active and ignored — consequence applies
	_expect("ignored crime reduces population", c.population < 100.0)

func _test_population_capped_by_housing() -> void:
	var c := CitySim.new(100000.0)
	_wire_row(c, [CitySim.Zone.RESIDENTIAL], CitySim.GRID_COLS)  # capacity = 1 * RESIDENTIAL_CAPACITY
	c.population = 99999.0  # way over capacity
	c.advance(1.0)
	_expect("population is capped at housing capacity",
		is_equal_approx(c.population, CitySim.RESIDENTIAL_CAPACITY)
		and is_equal_approx(c.housing_capacity(), CitySim.RESIDENTIAL_CAPACITY))

func _test_city_ages_in_years() -> void:
	var c := CitySim.new()
	var start_year := c.year()
	c.advance(CitySim.YEAR)  # one full year passes
	_expect("city age advances one year per YEAR seconds",
		start_year == 1 and c.year() == 2)

func _test_phase_tracks_population() -> void:
	var c := CitySim.new()
	var village := c.phase()
	c.population = 600.0
	var small := c.phase()
	c.population = 60000.0
	var metro := c.phase()
	_expect("phase tracks population",
		village == CitySim.Phase.VILLAGE
		and small == CitySim.Phase.SMALL_TOWN
		and metro == CitySim.Phase.METROPOLIS)

func _test_all_zones_unlocked_from_start() -> void:
	var c := CitySim.new(100000.0)
	var all_unlocked := true
	for zone in CitySim.ZONE_NAME:
		if not c.is_zone_unlocked(zone):
			all_unlocked = false
	var built_hospital := c.build(CitySim.Zone.HOSPITAL, 0)
	_expect("every zone is buildable from the start", all_unlocked and built_hospital)

func _test_save_load_round_trip() -> void:
	var a := CitySim.new(7777.0)
	a.population = 1234.0
	a.build(CitySim.Zone.COMMERCIAL, 0)
	a.build(CitySim.Zone.INDUSTRIAL, 1)
	a.indicators[CitySim.Indicator.SECURITY] = 42.0
	a.tax_rate = 0.12
	var b := CitySim.new()
	b.from_dict(a.to_dict())
	_expect("save/load round-trips the city",
		is_equal_approx(b.money, a.money)
		and is_equal_approx(b.population, a.population)
		and b.slots[0] == CitySim.Zone.COMMERCIAL
		and b.slots[1] == CitySim.Zone.INDUSTRIAL
		and is_equal_approx(b.indicators[CitySim.Indicator.SECURITY], 42.0)
		and is_equal_approx(b.tax_rate, 0.12))

# Build `zones` in a row that is powered (plant at the row start) and road-served
# (a road above each), so every placed building is functional. Row 1 (col 0..).
func _wire_row(c: CitySim, zones: Array, start: int) -> void:
	c.build(CitySim.Zone.POWER, start)
	for i in zones.size():
		var s: int = start + 1 + i
		c.build(CitySim.Zone.ROADS, s - CitySim.GRID_COLS)  # road above -> access
		c.build(zones[i], s)

func _expect(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
