## Goal: Socialize with other scavengers (scavenger only).
##
## Low-priority flocking behavior when satisfied.
extends GOAPGoal
class_name SocializeGoal


func _init() -> void:
	goal_name = &"Socialize"
	priority = 4.0
	desired_state = {&"socializing": true}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var energy_value := state.get(&"energy", 50.0) as float

	# Only socialize when well-fed
	if energy_value < 60.0:
		return 0.0

	return priority


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value >= 60.0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Socializing is ongoing
	return state.get(&"socializing", false) as bool
