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
	_test_commercial_zone_generates_revenue()
	_test_residential_zone_grows_population()
	_test_upkeep_charged_monthly()
	_test_net_drives_money()
	_test_slots_unlock_with_population()
	_test_indicators_start_at_default()
	_test_happiness_is_average_of_indicators()
	_test_indicators_decay_passively()
	_test_service_boosts_its_indicator()
	_test_energy_drains_faster_with_more_zones()
	_test_high_happiness_boosts_population()
	_test_low_happiness_causes_emigration()
	_test_crisis_starts_below_threshold()
	_test_no_crisis_above_threshold()
	_test_crisis_clears_on_recovery()
	_test_response_bumps_indicator_and_costs()
	_test_cannot_respond_without_money()
	_test_ignored_crime_reduces_population()
	_test_blackout_decays_all_indicators()

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

func _test_commercial_zone_generates_revenue() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.COMMERCIAL, 0)
	c.build(CitySim.Zone.COMMERCIAL, 1)
	_expect("commercial zones set revenue",
		is_equal_approx(c.revenue_per_sec, 2.0 * CitySim.COMMERCIAL_REVENUE))

func _test_residential_zone_grows_population() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.RESIDENTIAL, 0)
	c.build(CitySim.Zone.RESIDENTIAL, 1)
	c.build(CitySim.Zone.RESIDENTIAL, 2)  # 3 * (1/3) = 1 pop/sec
	c.advance(2.0)
	_expect("residential zones grow population", is_equal_approx(c.population, 2.0))

func _test_upkeep_charged_monthly() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.POLICE, 0)
	_expect("upkeep is monthly upkeep / MONTH",
		is_equal_approx(c.upkeep_per_sec, CitySim.ZONE_UPKEEP[CitySim.Zone.POLICE] / CitySim.MONTH))

func _test_net_drives_money() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.COMMERCIAL, 0)
	var start := c.money
	c.advance(1.0)
	_expect("money moves by net per second",
		is_equal_approx(c.money, start + c.net_per_sec()))

func _test_slots_unlock_with_population() -> void:
	var c := CitySim.new(10000.0)
	var before := c.slots.size()
	c.population = CitySim.POP_PER_SLOT  # one milestone worth of residents
	c.advance(0.0)  # triggers slot sync
	_expect("a slot unlocks per population milestone", c.slots.size() == before + 1)

func _test_indicators_start_at_default() -> void:
	var c := CitySim.new()
	_expect("indicators start at the default",
		is_equal_approx(c.indicators[CitySim.Indicator.SECURITY], CitySim.INDICATOR_START))

func _test_happiness_is_average_of_indicators() -> void:
	var c := CitySim.new()
	c.indicators[CitySim.Indicator.SECURITY] = 100.0
	c.indicators[CitySim.Indicator.EDUCATION] = 0.0
	# the other three stay at INDICATOR_START
	var start := CitySim.INDICATOR_START
	var expected := (100.0 + 0.0 + start + start + start) / 5.0
	_expect("happiness is the average of indicators", is_equal_approx(c.happiness(), expected))

func _test_indicators_decay_passively() -> void:
	var c := CitySim.new()
	c.advance(10.0)
	_expect("indicators decay passively",
		is_equal_approx(c.indicators[CitySim.Indicator.SECURITY],
			CitySim.INDICATOR_START - CitySim.BASE_DECAY * 10.0))

func _test_service_boosts_its_indicator() -> void:
	var c := CitySim.new(10000.0)
	c.build(CitySim.Zone.POLICE, 0)
	c.advance(1.0)
	# +SERVICE_BOOST from police, -BASE_DECAY passive.
	_expect("a service boosts its indicator",
		is_equal_approx(c.indicators[CitySim.Indicator.SECURITY],
			CitySim.INDICATOR_START + CitySim.SERVICE_BOOST - CitySim.BASE_DECAY))

func _test_energy_drains_faster_with_more_zones() -> void:
	var quiet := CitySim.new(10000.0)
	quiet.advance(1.0)
	var busy := CitySim.new(10000.0)
	busy.build(CitySim.Zone.COMMERCIAL, 0)
	busy.build(CitySim.Zone.COMMERCIAL, 1)
	busy.advance(1.0)
	_expect("energy drains faster with more zones",
		busy.indicators[CitySim.Indicator.ENERGY] < quiet.indicators[CitySim.Indicator.ENERGY])

func _test_high_happiness_boosts_population() -> void:
	var c := CitySim.new(10000.0)
	for ind in CitySim.INDICATORS:
		c.indicators[ind] = 100.0  # happiness 100 -> immigration
	c.build(CitySim.Zone.RESIDENTIAL, 0)
	c.build(CitySim.Zone.RESIDENTIAL, 1)
	c.build(CitySim.Zone.RESIDENTIAL, 2)  # 1 pop/sec base
	c.advance(2.0)
	_expect("high happiness boosts population (1.5x)", is_equal_approx(c.population, 3.0))

func _test_low_happiness_causes_emigration() -> void:
	var c := CitySim.new(10000.0)
	for ind in CitySim.INDICATORS:
		c.indicators[ind] = 10.0  # happiness 10 -> emigration
	c.build(CitySim.Zone.RESIDENTIAL, 0)
	c.build(CitySim.Zone.RESIDENTIAL, 1)
	c.build(CitySim.Zone.RESIDENTIAL, 2)  # 1 pop/sec base
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

func _test_blackout_decays_all_indicators() -> void:
	var c := CitySim.new()
	c.indicators[CitySim.Indicator.ENERGY] = 20.0
	c.advance(0.5)  # blackout begins
	var sec_before: float = c.indicators[CitySim.Indicator.SECURITY]
	c.advance(1.0)  # active blackout drags every indicator down extra
	var sec_after: float = c.indicators[CitySim.Indicator.SECURITY]
	var drop := sec_before - sec_after
	_expect("blackout decays all indicators faster than normal",
		drop > CitySim.BASE_DECAY + 0.0001)

func _expect(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
