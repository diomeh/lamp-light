## Goal: Scavenge corpses for food (scavenger only).
##
## Primary scavenger behavior.
extends GOAPGoal
class_name ScavengeGoal


func _init() -> void:
	goal_name = &"Scavenge"
	priority = 12.0
	desired_state = {&"energy": 85}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var energy_value := state.get(&"energy", 50.0) as float
	var corpse_detected := state.get(&"corpse_detected", false) as bool

	if not corpse_detected:
		return 0.0

	# Priority increases as energy decreases
	return priority * (1.0 - energy_value / 100.0)


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	var corpse_detected := state.get(&"corpse_detected", false) as bool
	return energy_value < 85.0 and corpse_detected


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value >= 80.0
