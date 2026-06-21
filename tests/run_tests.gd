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
	var ok := c.build(CitySim.Zone.SERVICE, 0)  # costs 1500
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
	c.build(CitySim.Zone.SERVICE, 0)
	_expect("upkeep is monthly upkeep / MONTH",
		is_equal_approx(c.upkeep_per_sec, CitySim.ZONE_UPKEEP[CitySim.Zone.SERVICE] / CitySim.MONTH))

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

func _expect(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
