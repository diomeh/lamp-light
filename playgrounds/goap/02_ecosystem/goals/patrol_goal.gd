## Goal: Patrol territory (predator only).
##
## Low-priority wandering behavior.
extends GOAPGoal
class_name PatrolGoal


func _init() -> void:
	goal_name = &"Patrol"
	priority = 3.0
	desired_state = {&"patrolling": true}


func get_priority(_state: Dictionary[StringName, Variant]) -> float:
	return priority


func is_relevant(_state: Dictionary[StringName, Variant]) -> bool:
	# Always relevant as fallback behavior
	return true


func is_achieved(_state: Dictionary[StringName, Variant]) -> bool:
	# Never truly achieved - continuous behavior
	return false
