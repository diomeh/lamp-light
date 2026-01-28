## Goal: Fall back when enemies too close (archers).
extends GOAPGoal
class_name FallBackGoal

func _init() -> void:
	goal_name = &"FallBack"
	priority = 20.0  # High priority!
	desired_state = {&"safe_distance": true}

func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var enemies_close := state.get(&"enemies_in_melee_range", 0) as int
	return priority if enemies_close > 0 else 0.0

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"enemies_in_melee_range", 0) as int > 0

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"safe_distance", false) as bool
