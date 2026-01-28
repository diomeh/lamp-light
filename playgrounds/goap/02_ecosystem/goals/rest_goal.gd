## Goal: Rest to conserve energy (predator only).
##
## Pursued when predator is well-fed.
extends GOAPGoal
class_name PredatorRestGoal


func _init() -> void:
	goal_name = &"Rest"
	priority = 5.0
	desired_state = {&"rested": true}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var energy_value := state.get(&"energy", 50.0) as float

	# Rest when well-fed
	if energy_value < 70.0:
		return 0.0

	return priority


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value >= 70.0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Resting is never truly "achieved" - it's an ongoing state
	return state.get(&"rested", false) as bool
