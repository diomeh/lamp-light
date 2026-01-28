## Action: Socialize with other scavengers (scavenger).
##
## Moves toward other scavengers to form groups.
extends GOAPAction
class_name SocializeAction

var _socialize_duration: float = 4.0
var _socialize_timer: float = 0.0
var _target_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	action_name = &"Socialize"
	cost = 1.0
	preconditions = {}
	effects = {&"socializing": true}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value >= 60.0


func enter(agent: GOAPAgent) -> void:
	_socialize_timer = 0.0
	agent.blackboard.set_value(&"socializing", false)

	# Find nearest scavenger
	var creature := agent as CreatureAgent
	if creature:
		var nearby := creature.detect_creatures_in_range(120.0, CreatureAgent.CreatureType.SCAVENGER)
		if nearby.size() > 0:
			_target_pos = nearby[0].actor.global_position
		else:
			# No one to socialize with, just wander
			_target_pos = creature.actor.global_position + Vector2(
				randf_range(-50.0, 50.0),
				randf_range(-50.0, 50.0)
			)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_socialize_timer += delta

	var creature := agent as CreatureAgent
	if creature:
		creature.move_toward(_target_pos, delta * 0.6)  # Slow approach

		# Minimal energy consumption
		creature.energy = maxf(creature.energy - delta * 0.5, 0.0)
		agent.blackboard.set_value(&"energy", creature.energy)

	if _socialize_timer >= _socialize_duration:
		agent.blackboard.set_value(&"socializing", true)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_socialize_timer = 0.0
