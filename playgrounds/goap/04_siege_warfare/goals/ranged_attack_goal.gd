## Goal: Attack from range (archers).
extends GOAPGoal
class_name RangedAttackGoal

func _init() -> void:
	goal_name = &"RangedAttack"
	priority = 14.0
	desired_state = {&"attacking": true}

func get_priority(state: Dictionary[StringName, Variant]) -> float:
	return priority if state.get(&"has_target", false) else 0.0

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"has_target", false) as bool

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"attacking", false) as bool
