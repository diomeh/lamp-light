## Goal: Idle when no work available.
##
## Lowest priority fallback goal.
extends GOAPGoal
class_name IdleGoal


func _init() -> void:
	goal_name = &"Idle"
	priority = 1.0
	desired_state = {&"idle": true}


func get_priority(_state: Dictionary[StringName, Variant]) -> float:
	return priority


func is_relevant(_state: Dictionary[StringName, Variant]) -> bool:
	# Always relevant as fallback
	return true


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Never truly achieved - continuous state
	return state.get(&"idle", false) as bool
