class_name ReachTarget
extends GOAPGoal

## Goal to reach a designated target position.
## This goal is relevant when the agent has a target but hasn't reached it yet.


func _init() -> void:
	goal_name = "Reach Target"
	priority = 10.0

	# Desired state: Agent should be at target
	desired_state = {
		"at_target": true
	}


func is_relevant(_agent: GOAPAgent) -> bool:
	return true


func get_priority(_agent: GOAPAgent) -> float:
	# Could make priority dynamic based on distance, urgency, etc.
	return priority
