## Goal to reach a designated target position.
##
## Always relevant - agents will continuously seek targets.[br]
## Satisfied when [code]at_target: true[/code] in world state.[br][br]
##
## [b]Desired state:[/b] [code]{at_target: true}[/code][br][br]
##
## See also:[br]
## [GOAPGoal][br]
class_name ReachTarget
extends GOAPGoal


func _init() -> void:
	goal_name = "Reach Target"
	priority = 10.0

	# Desired state: Agent should be at target
	desired_state = {
		"at_target": true,
	}

### Always relevant - agents will always consider this goal.[br][br]
##
## [param _agent] Unused.[br]
## Returns [code]true[/code].
func is_relevant(_agent: GOAPAgent) -> bool:
	return true

## Static priority for this goal.[br][br]
##
## [param _agent] Unused.[br]
## Returns default priority value; higher is more important.
##
## See also:[br]
## [member GOAPGoal.priority]
func get_priority(_agent: GOAPAgent) -> float:
	# Could make priority dynamic based on distance, urgency, etc.
	return priority
