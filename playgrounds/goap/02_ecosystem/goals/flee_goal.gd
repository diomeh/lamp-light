## Goal: Flee from nearby predators (herbivore only).
##
## Highest priority reactive goal.[br]
## Overrides all other goals when predator is nearby.
extends GOAPGoal
class_name FleeGoal


func _init() -> void:
	goal_name = &"Flee"
	priority = 100.0  # Extremely high - survival instinct
	desired_state = {&"threat_detected": false}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var threat_detected := state.get(&"threat_detected", false) as bool
	var threat_distance := state.get(&"threat_distance", 1000.0) as float

	if not threat_detected:
		return 0.0

	# Priority increases as threat gets closer
	# Within 80 units, priority scales from 50-100
	var distance_factor := clampf(1.0 - (threat_distance / 80.0), 0.0, 1.0)
	return priority * distance_factor


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"threat_detected", false) as bool


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Achieved when threat is gone or far away
	var threat_detected := state.get(&"threat_detected", false) as bool
	var threat_distance := state.get(&"threat_distance", 1000.0) as float
	return not threat_detected or threat_distance > 100.0
