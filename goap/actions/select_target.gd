class_name SelectTarget
extends GOAPAction

## Action that selects a desired global space vector as target for the actor.
## Runs every frame until target is selected.


func _init() -> void:
	action_name = "Select Target"
	cost = 1.0

	preconditions = {
		"lights_available": true
	}

	effects = {
		"has_target": true,
	}


## Determine if given agent can perform this action.
func can_perform(_agent: GOAPAgent) -> bool:
	return true


## Execute the action. Called every frame while the action is active.
## Returns true when the action is complete, false while it's still running.
func perform(agent: GOAPAgent) -> bool:
	var entity := agent.entity
	var blackboard := agent.blackboard
	var world_state := agent.world_state

	# Iterate lights and find closest one
	var closest: Vector3
	var closest_distance = - INF

	for pos in world_state.get_value("light_positions"):
		var distance := absf(entity.global_position.distance_to(pos))
		if not closest or closest_distance > distance:
			closest = pos
			closest_distance = distance

	if not closest:
		return false

	blackboard.set_value("has_target", true)
	blackboard.set_value("target_position", closest)

	return true
