## Goal: Reproduce when conditions are favorable (all creatures).
##
## Pursued when energy is above reproduction threshold.
extends GOAPGoal
class_name ReproduceGoal


func _init() -> void:
	goal_name = &"Reproduce"
	priority = 8.0
	desired_state = {&"reproduced": true}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	var can_reproduce := state.get(&"can_reproduce", false) as bool

	if not can_reproduce:
		return 0.0

	return priority


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"can_reproduce", false) as bool


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"reproduced", false) as bool


func after_plan_complete(agent: GOAPAgent) -> void:
	# Reset reproduction flag after cooldown
	agent.blackboard.set_value(&"reproduced", false)
	agent.blackboard.set_value(&"can_reproduce", false)
