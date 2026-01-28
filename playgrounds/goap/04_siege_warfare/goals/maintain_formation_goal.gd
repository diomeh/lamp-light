## Goal: Maintain formation position.
extends GOAPGoal
class_name MaintainFormationGoal

func _init() -> void:
	goal_name = &"MaintainFormation"
	priority = 12.0
	desired_state = {&"in_formation": true}

func get_priority(state: Dictionary[StringName, Variant]) -> float:
	return priority if state.get(&"has_formation", false) else 0.0

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"has_formation", false) as bool

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"in_formation", false) as bool
