## Goal: Advance toward objective.
extends GOAPGoal
class_name AdvanceGoal

func _init() -> void:
	goal_name = &"Advance"
	priority = 8.0
	desired_state = {&"advancing": true}

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return not state.get(&"is_dead", false)

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"advancing", false) as bool
