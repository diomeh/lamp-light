## Goal: Issue tactical retreat order.
extends GOAPGoal
class_name TacticalRetreatGoal

func _init() -> void:
	goal_name = &"TacticalRetreat"
	priority = 25.0  # Very high!
	desired_state = {&"retreat_ordered": true}

func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var health := state.get(&"health", 100.0) as float
	return priority if health < 30.0 else 0.0

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"health", 100.0) as float < 30.0

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"retreat_ordered", false) as bool
