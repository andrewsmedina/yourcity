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
var selected_zone: CitySim.Zone = CitySim.Zone.RESIDENTIAL  ## zone the next build places

const SAVE_PATH := "user://taskbarcity_save.json"
const AUTOSAVE_EVERY := 10.0

var _active := {}  # mirror of active crises, for edge detection
var _autosave_accum := 0.0

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	_autosave_accum += delta
	if _autosave_accum >= AUTOSAVE_EVERY:
		_autosave_accum = 0.0
		save_game()
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

## Reset to a fresh city (debug/recovery), persisting the clean state.
func reset() -> void:
	sim = CitySim.new()
	_active = {}
	save_game()
	money_changed.emit(sim.money)
	population_changed.emit(sim.population)
	city_changed.emit()

## Attempt to build a zone into a slot; emits updates and returns success.
func build(zone: CitySim.Zone, slot_index: int) -> bool:
	if not sim.build(zone, slot_index):
		return false
	money_changed.emit(sim.money)
	city_changed.emit()
	return true

## Demolish whatever is on a slot; emits updates and returns success.
func demolish(slot_index: int) -> bool:
	if not sim.demolish(slot_index):
		return false
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

# --- Save / load (#40, #41) ---

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("TaskbarCity: could not open save file for writing")
		return
	f.store_string(JSON.stringify(sim.to_dict()))
	f.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("TaskbarCity: save file is corrupt, ignoring")
		return false
	sim.from_dict(data)
	city_changed.emit()
	return true

func _exit_tree() -> void:
	save_game()
