class_name MoveTo
extends GOAPAction

## Action that moves the agent toward its target position.
## Runs every frame until the agent reaches the target.


func _init() -> void:
	action_name = "Move To Target"
	cost = 1.0

	# Preconditions: Must have a target and movement must be allowed
	preconditions = {
		"has_target": true,
		"movement_allowed": true,
		"at_target": false
	}

	# Effects: Agent will be at target after this action
	effects = {
		"at_target": true
	}


func can_perform(agent: GOAPAgent) -> bool:
	return agent.blackboard.get_value("has_target", false)


func enter(agent: GOAPAgent) -> void:
	print("Starting movement to target: ", agent.blackboard.get_value("target_position"))


func perform(agent: GOAPAgent) -> bool:
	var blackboard = agent.blackboard

	var target_pos: Vector3 = blackboard.get_value("target_position", Vector3.ZERO)
	var move_speed: float = blackboard.get_value("move_speed", 5.0)
	var threshold: float = blackboard.get_value("arrival_threshold", 0.5)

	var current_pos: Vector3 = agent.global_position
	var distance: float = current_pos.distance_to(target_pos)

	# Check if we've arrived
	if distance <= threshold:
		# Stop the agent
		agent.linear_velocity = Vector3.ZERO
		blackboard.set_value("at_target", true)
		return true  # Action complete

	# Move toward target
	var direction: Vector3 = (target_pos - current_pos).normalized()
	var velocity: Vector3 = direction * move_speed

	# Set velocity (for RigidBody3D)
	agent.linear_velocity = velocity

	# Make agent look in movement direction
	if direction.length() > 0.01:
		var look_target = current_pos + direction
		agent.look_at(look_target, Vector3.UP)

	return false  # Still moving


func exit(agent: GOAPAgent) -> void:
	# Ensure agent stops moving
	agent.linear_velocity = Vector3.ZERO
	print("Reached target position")
