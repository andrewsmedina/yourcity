extends Node

## Live city simulation wired into the game loop. Owns a CitySim, ticks it every
## frame, and emits signals the UI renders. Gameplay and UI talk to this
## autoload; they never touch CitySim directly.

signal money_changed(money: float)
signal population_changed(population: float)
signal city_changed  ## zones built or slots unlocked — the view should refresh
signal crisis_started(crisis: CitySim.CrisisType)
signal crisis_ended(crisis: CitySim.CrisisType)

var sim := CitySim.new()

var _active := {}  # mirror of active crises, for edge detection

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
	_diff_crises()

## Attempt to build a zone into a slot; emits updates and returns success.
func build(zone: CitySim.Zone, slot_index: int) -> bool:
	if not sim.build(zone, slot_index):
		return false
	money_changed.emit(sim.money)
	city_changed.emit()
	return true

## Pay for and apply a crisis response; emits updates and returns success.
func respond(crisis: CitySim.CrisisType, response_index: int) -> bool:
	if not sim.respond(crisis, response_index):
		return false
	money_changed.emit(sim.money)
	if not sim.is_crisis_active(crisis):
		_active.erase(crisis)
		crisis_ended.emit(crisis)
	return true

func _diff_crises() -> void:
	var now := {}
	for crisis in sim.active_crises():
		now[crisis] = true
		if not _active.has(crisis):
			crisis_started.emit(crisis)
	for crisis in _active.keys():
		if not now.has(crisis):
			crisis_ended.emit(crisis)
	_active = now
