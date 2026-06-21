extends SceneTree

## Headless test runner for the pure simulation classes.
## Run with: godot --headless --script tests/run_tests.gd
## Exits non-zero if any check fails (CI-friendly).

var _failures := 0

func _initialize() -> void:
	_test_money_accrues_from_revenue()
	_test_no_revenue_keeps_money_flat()
	_test_commercial_zone_generates_money()
	_test_industrial_zone_generates_money()
	_test_residential_zone_grows_population()
	_test_service_zone_earns_nothing()
	_test_removing_zones_floors_at_zero()

	if _failures > 0:
		push_error("%d test(s) failed" % _failures)
		quit(1)
	else:
		print("all tests passed")
		quit(0)

func _test_money_accrues_from_revenue() -> void:
	var c := CitySim.new(100.0)
	c.revenue_per_sec = 10.0
	c.advance(2.0)
	_expect("money accrues from revenue", is_equal_approx(c.money, 120.0))

func _test_no_revenue_keeps_money_flat() -> void:
	var c := CitySim.new(500.0)
	c.advance(5.0)
	_expect("no revenue keeps money flat", is_equal_approx(c.money, 500.0))

func _test_commercial_zone_generates_money() -> void:
	var c := CitySim.new(0.0)
	c.add_zone(CitySim.Zone.COMMERCIAL, 3)
	c.advance(1.0)
	_expect("commercial zones generate money", is_equal_approx(c.money, 3.0 * CitySim.COMMERCIAL_REVENUE))

func _test_industrial_zone_generates_money() -> void:
	var c := CitySim.new(0.0)
	c.add_zone(CitySim.Zone.INDUSTRIAL, 2)
	c.advance(1.0)
	_expect("industrial zones generate money", is_equal_approx(c.money, 2.0 * CitySim.INDUSTRIAL_REVENUE))

func _test_residential_zone_grows_population() -> void:
	var c := CitySim.new()
	c.add_zone(CitySim.Zone.RESIDENTIAL, 3)  # 3 * (1/3) = 1 pop/sec
	c.advance(2.0)
	_expect("residential zones grow population", is_equal_approx(c.population, 2.0))

func _test_service_zone_earns_nothing() -> void:
	var c := CitySim.new(100.0)
	c.add_zone(CitySim.Zone.SERVICE, 5)
	c.advance(10.0)
	_expect("service zones earn nothing yet", is_equal_approx(c.money, 100.0))

func _test_removing_zones_floors_at_zero() -> void:
	var c := CitySim.new()
	c.add_zone(CitySim.Zone.COMMERCIAL, 1)
	c.add_zone(CitySim.Zone.COMMERCIAL, -5)
	_expect("zone counts never go negative", c.zone_count(CitySim.Zone.COMMERCIAL) == 0)

func _expect(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
