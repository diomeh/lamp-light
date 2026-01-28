## Goal: Operate siege equipment.
extends GOAPGoal
class_name OperateSiegeGoal

func _init() -> void:
	goal_name = &"OperateSiege"
	priority = 18.0
	desired_state = {&"operating_equipment": true}

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"siege_equipment_available", false) as bool

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"operating_equipment", false) as bool
