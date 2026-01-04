## Action that selects the closest light as navigation target.
##
## Reads [code]light_positions[/code] from world state and sets
## [code]target_position[/code] in blackboard to nearest light.[br][br]
##
## [b]Preconditions:[/b] [code]{lights_available: true}[/code]
## [br]
## [b]Effects:[/b] [code]{has_target: true}[/code][br][br]
##
## See also:[br]
## [MoveTo]
class_name SelectTarget
extends GOAPAction


func _init() -> void:
	action_name = "Select Target"
	cost = 1.0

	preconditions = {
		"lights_available": true,
	}

	effects = {
		"has_target": true,
	}


## Always returns [code]true[/code] - target selection is always possible.[br][br]
##
## [param _agent] Unused.[br]
## Returns [code]true[/code].
func can_perform(_agent: GOAPAgent) -> bool:
	return true


## Finds closest light and sets it as target.[br][br]
##
## Reads from world state:[br]
## - [code]light_positions[/code]: Array of [Vector3] positions[br][br]
##
## Updates blackboard:[br]
## - [code]has_target[/code]: Set to [code]true[/code][br]
## - [code]target_position[/code]: Closest light position[br][br]
##
## [param agent] Agent performing the action.[br]
## Returns [code]true[/code] if target found, [code]false[/code] otherwise.
func perform(agent: GOAPAgent, _delta: float) -> bool:
	var actor := agent.actor
	var blackboard := agent.blackboard

	# Iterate lights and find closest one
	var closest: Vector3
	var closest_distance = - INF

	for pos in WorldState.get_value("light_positions"):
		var distance := absf(actor.global_position.distance_to(pos))
		if not closest or closest_distance > distance:
			closest = pos
			closest_distance = distance

	if not closest:
		return false

	blackboard.set_value("has_target", true)
	blackboard.set_value("target_position", closest)

	return true
