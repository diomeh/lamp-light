## Goal: Graze on grass to restore energy (herbivore only).
##
## Primary herbivore behavior when not threatened.
extends GOAPGoal
class_name GrazeGoal


func _init() -> void:
	goal_name = &"Graze"
	priority = 10.0
	desired_state = {&"energy": 80}  # Target energy level


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var energy_value := state.get(&"energy", 50.0) as float

	# Priority increases as energy decreases
	# 0 energy = 10 priority, 100 energy = 0 priority
	return priority * (1.0 - energy_value / 100.0)


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value < 80.0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value >= 75.0
