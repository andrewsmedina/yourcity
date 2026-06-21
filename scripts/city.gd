extends Node

## Live city simulation wired into the game loop. Owns a CitySim, ticks it every
## frame, and emits signals the UI renders. Gameplay and UI talk to this
## autoload; they never touch CitySim directly.

signal money_changed(money: float)

var sim := CitySim.new()

func _process(delta: float) -> void:
	var before := sim.money
	sim.advance(delta)
	if not is_equal_approx(before, sim.money):
		money_changed.emit(sim.money)
