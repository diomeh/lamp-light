## Goal: Command troops (commanders).
extends GOAPGoal
class_name CommandTroopsGoal

func _init() -> void:
	goal_name = &"CommandTroops"
	priority = 20.0
	desired_state = {&"troops_commanded": true}

func is_relevant(_state: Dictionary[StringName, Variant]) -> bool:
	return true

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"troops_commanded", false) as bool
