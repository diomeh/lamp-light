## Action that navigates agent toward its target position.
##
## Requires [code]has_target: true[/code] and [code]target_position[/code] in blackboard.[br]
## Completes when entity reaches within threshold distance.[br][br]
##
## [b]Preconditions:[/b] [code]{has_target: true}[/code]
## [br]
## [b]Effects:[/b] [code]{at_target: true}[/code][br][br]
##
## See also:[br]
## [SelectTarget]
class_name MoveTo
extends GOAPAction


func _init() -> void:
	action_name = "Move To Target"
	cost = 1.0

	preconditions = {
		"has_target": true,
	}

	# Effects: Agent will be at target after this action
	effects = {
		"at_target": true,
	}


## Always returns [code]true[/code] - movement is always possible.[br][br]
##
## [param _agent] Unused.[br]
## Returns [code]true[/code].
func can_perform(_agent: GOAPAgent) -> bool:
	return true


## Called once when the action starts executing.[br]
## Override for initialization logic (e.g., starting animations, setting up state).[br][br]
##
## [param agent] The agent starting this action.
func enter(agent: GOAPAgent) -> void:
	var target = agent.blackboard.get_value("target_position")
	print("Begin '%s' action: target %s" % [action_name, target])


## Moves entity toward [code]target_position[/code] each frame.[br][br]
##
## Reads from blackboard:[br]
## - [code]target_position[/code]: [Vector3] destination[br]
## - [code]move_speed[/code]: Movement speed (default 5.0)[br][br]
##
## Updates blackboard on completion:[br]
## - [code]at_target[/code]: Set to [code]true[/code][br]
## - [code]has_target[/code]: Set to [code]false[/code][br][br]
##
## [param agent] Agent performing the action.[br]
## Returns [code]true[/code] when within 0.5 units of target.
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


## Called once when the action finishes or is interrupted.[br]
## Override for cleanup logic (e.g., stopping animations, resetting state).[br][br]
##
## [param agent] The agent ending this action.
func exit(agent: GOAPAgent) -> void:
	# Ensure agent stops moving
	var entity := agent.entity
	if entity.has_method("stop_moving"):
		entity.stop_moving()
