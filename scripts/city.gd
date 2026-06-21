extends Node

## Live city simulation wired into the game loop. Owns a CitySim, ticks it every
## frame, and emits signals the UI renders. Gameplay and UI talk to this
## autoload; they never touch CitySim directly.

signal money_changed(money: float)
signal population_changed(population: float)
signal city_changed  ## zones built or slots unlocked — the view should refresh

var sim := CitySim.new()

func _process(delta: float) -> void:
	var prev_money := sim.money
	var prev_pop := sim.population
	var prev_slots := sim.slots.size()
	sim.advance(delta)
	if not is_equal_approx(prev_money, sim.money):
		money_changed.emit(sim.money)
	if not is_equal_approx(prev_pop, sim.population):
		population_changed.emit(sim.population)
	if prev_slots != sim.slots.size():
		city_changed.emit()  # a new slot unlocked

## Attempt to build a zone into a slot; emits updates and returns success.
func build(zone: CitySim.Zone, slot_index: int) -> bool:
	if not sim.build(zone, slot_index):
		return false
	money_changed.emit(sim.money)
	city_changed.emit()
	return true
