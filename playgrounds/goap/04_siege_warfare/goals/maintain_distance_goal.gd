## Goal: Maintain distance from enemies.
extends GOAPGoal
class_name MaintainDistanceGoal

func _init() -> void:
	goal_name = &"MaintainDistance"
	priority = 10.0
	desired_state = {&"at_optimal_range": true}

func is_relevant(_state: Dictionary[StringName, Variant]) -> bool:
	return true

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"at_optimal_range", false) as bool
