class_name MoveTo
extends GOAPAction

## Action that moves the agent toward its target position.
## Runs every frame until the agent reaches the target.


func _init() -> void:
	action_name = "Move To Target"
	cost = 1.0

	# Effects: Agent will be at target after this action
	effects = {
		"at_target": true
	}


## Determine if given agent can perform this action.
func can_perform(_agent: GOAPAgent) -> bool:
	return true


func enter(agent: GOAPAgent) -> void:
	var target = agent.blackboard.get_value("target_position")
	print("Begin '%s' action: target %s" % [action_name, target])


## Execute the action. Called every frame while the action is active.
## Returns true when the action is complete, false while it's still running.
func perform(agent: GOAPAgent) -> bool:
	var entity := agent.entity
	var blackboard := agent.blackboard

	var target_pos: Vector3 = blackboard.get_value("target_position", Vector3.ZERO)
	var move_speed: float = blackboard.get_value("move_speed", 5.0)

	var threshold: float = 0.5
	var distance: float = entity.global_position.distance_to(target_pos)

	# Check if we've arrived
	if distance <= threshold:
		# Use entity's movement API
		if entity.has_method("stop_moving"):
			entity.stop_moving()

		agent.blackboard.set_value("at_target", true)
		agent.blackboard.set_value("has_target", false)

		return true

	if entity.has_method("move_toward"):
		entity.move_toward(target_pos, move_speed)

	if entity.has_method("look_toward"):
		entity.look_toward(target_pos)

	return false


func exit(agent: GOAPAgent) -> void:
	# Ensure agent stops moving
	var entity := agent.entity
	if entity.has_method("stop_moving"):
		entity.stop_moving()
