## Goal: Survive thirst by drinking water.
##
## Priority increases as thirst increases.[br]
## Becomes critical above 70 thirst.
extends GOAPGoal
class_name SurviveThirstGoal


func _init() -> void:
	goal_name = &"SurviveThirst"
	priority = 10.0
	desired_state = {&"thirst": 0}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var thirst_value := state.get(&"thirst", 0.0) as float
	# Priority scales with thirst: 0-100 thirst maps to 0-10 priority
	# Critical above 70 (priority > 7)
	return priority * (thirst_value / 100.0)


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	# Only pursue if thirsty enough
	var thirst_value := state.get(&"thirst", 0.0) as float
	return thirst_value > 30.0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Achieved when thirst is low
	var thirst_value := state.get(&"thirst", 0.0) as float
	return thirst_value < 20.0
