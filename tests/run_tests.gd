extends SceneTree

## Headless test runner for the pure simulation classes.
## Run with: godot --headless --script tests/run_tests.gd
## Exits non-zero if any check fails (CI-friendly).

var _failures := 0

func _initialize() -> void:
	_test_money_accrues_from_revenue()
	_test_no_revenue_keeps_money_flat()

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

func _expect(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
