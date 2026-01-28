## Goal: Survive hunger by eating food.
##
## Priority increases as hunger increases.[br]
## Becomes critical above 70 hunger.
extends GOAPGoal
class_name SurviveHungerGoal


func _init() -> void:
	goal_name = &"SurviveHunger"
	priority = 10.0
	desired_state = {&"hunger": 0}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var hunger_value := state.get(&"hunger", 0.0) as float
	# Priority scales with hunger: 0-100 hunger maps to 0-10 priority
	# Critical above 70 (priority > 7)
	return priority * (hunger_value / 100.0)


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	# Only pursue if hungry enough
	var hunger_value := state.get(&"hunger", 0.0) as float
	return hunger_value > 30.0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Achieved when hunger is low
	var hunger_value := state.get(&"hunger", 0.0) as float
	return hunger_value < 20.0
