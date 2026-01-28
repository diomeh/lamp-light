## Goal: Contribute resources to community stockpile.
##
## Lowest priority goal - only pursued when all needs are met.[br]
## Encourages resource gathering for the community.
extends GOAPGoal
class_name ContributeGoal


func _init() -> void:
	goal_name = &"Contribute"
	priority = 3.0
	desired_state = {&"contributed": true}


func get_priority(_state: Dictionary[StringName, Variant]) -> float:
	# Base priority, only pursued when other needs are met
	return priority


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	# Only contribute if not hungry, thirsty, or tired
	var hunger_value := state.get(&"hunger", 0.0) as float
	var thirst_value := state.get(&"thirst", 0.0) as float
	var stamina_value := state.get(&"stamina", 100.0) as float

	return hunger_value < 40.0 and thirst_value < 40.0 and stamina_value > 50.0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Never truly achieved - always room to contribute more
	# But we'll say it's achieved if recently contributed
	return state.get(&"contributed", false) as bool


func after_plan_complete(agent: GOAPAgent) -> void:
	# Reset contributed flag after a delay
	# This allows the goal to be pursued again
	agent.blackboard.set_value(&"contributed", false)
