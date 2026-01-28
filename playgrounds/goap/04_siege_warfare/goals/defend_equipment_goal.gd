## Goal: Defend siege equipment.
extends GOAPGoal
class_name DefendEquipmentGoal

func _init() -> void:
	goal_name = &"DefendEquipment"
	priority = 16.0
	desired_state = {&"equipment_defended": true}

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"equipment_under_attack", false) as bool

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"equipment_defended", false) as bool
