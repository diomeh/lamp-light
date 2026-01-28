## Action: Patrol territory randomly (predator).
##
## Wanders to random locations.
extends GOAPAction
class_name PatrolAction

var _patrol_target: Vector2 = Vector2.ZERO
var _patrol_timer: float = 0.0
var _patrol_duration: float = 5.0


func _init() -> void:
	action_name = &"Patrol"
	cost = 1.5
	preconditions = {}
	effects = {&"patrolling": true}


func can_execute(_state: Dictionary[StringName, Variant]) -> bool:
	return true  # Always can patrol


func enter(agent: GOAPAgent) -> void:
	_patrol_timer = 0.0
	agent.blackboard.set_value(&"patrolling", false)

	# Pick random patrol target
	var creature := agent as CreatureAgent
	if creature:
		var ecosystem := creature.actor.get_parent() as Node
		if ecosystem and ecosystem.has_method("get_random_position"):
			_patrol_target = ecosystem.get_random_position()
		else:
			_patrol_target = creature.actor.global_position + Vector2(
				randf_range(-200.0, 200.0),
				randf_range(-200.0, 200.0)
			)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_patrol_timer += delta

	var creature := agent as CreatureAgent
	if creature:
		var distance := creature.move_toward(_patrol_target, delta * 0.5)  # Slow patrol

		# Consume minimal energy while patrolling
		creature.energy = maxf(creature.energy - delta * 1.0, 0.0)
		agent.blackboard.set_value(&"energy", creature.energy)

		if distance < 20.0 or _patrol_timer >= _patrol_duration:
			agent.blackboard.set_value(&"patrolling", true)
			return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_patrol_timer = 0.0
