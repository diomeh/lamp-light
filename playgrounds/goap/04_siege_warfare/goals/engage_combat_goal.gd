## Goal: Engage in combat with nearby enemies.
extends GOAPGoal
class_name EngageCombatGoal

func _init() -> void:
	goal_name = &"EngageCombat"
	priority = 15.0
	desired_state = {&"in_combat": true}

func get_priority(state: Dictionary[StringName, Variant]) -> float:
	return priority if state.get(&"has_target", false) else 0.0

func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"has_target", false) as bool and not state.get(&"is_dead", false)

func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"in_combat", false) as bool
