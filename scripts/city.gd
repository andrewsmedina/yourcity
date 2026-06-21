extends Node

## Live city simulation wired into the game loop. Owns a CitySim, ticks it every
## frame, and emits signals the UI renders. Gameplay and UI talk to this
## autoload; they never touch CitySim directly.

signal money_changed(money: float)
signal population_changed(population: float)

var sim := CitySim.new()

func _process(delta: float) -> void:
	var prev_money := sim.money
	var prev_pop := sim.population
	sim.advance(delta)
	if not is_equal_approx(prev_money, sim.money):
		money_changed.emit(sim.money)
	if not is_equal_approx(prev_pop, sim.population):
		population_changed.emit(sim.population)
