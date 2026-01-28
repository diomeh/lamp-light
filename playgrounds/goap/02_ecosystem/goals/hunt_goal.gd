## Goal: Hunt herbivores for food (predator only).
##
## Primary predator behavior when hungry.
extends GOAPGoal
class_name HuntGoal


func _init() -> void:
	goal_name = &"Hunt"
	priority = 15.0
	desired_state = {&"energy": 90}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var energy_value := state.get(&"energy", 50.0) as float

	# Only hunt when hungry
	if energy_value > 70.0:
		return 0.0

	# Priority increases as energy decreases
	return priority * (1.0 - energy_value / 100.0)


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	var prey_detected := state.get(&"prey_detected", false) as bool
	return energy_value < 70.0 and prey_detected


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value >= 85.0
