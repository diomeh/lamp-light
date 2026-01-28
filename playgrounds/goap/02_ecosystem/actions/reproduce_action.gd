## Action: Reproduce to create offspring (all creatures).
##
## Spawns a new creature of the same type.
extends GOAPAction
class_name ReproduceAction

var _reproduce_duration: float = 2.0
var _reproduce_timer: float = 0.0


func _init() -> void:
	action_name = &"Reproduce"
	cost = 4.0
	preconditions = {&"can_reproduce": true}
	effects = {&"reproduced": true}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"can_reproduce", false) as bool


func enter(agent: GOAPAgent) -> void:
	_reproduce_timer = 0.0
	agent.blackboard.set_value(&"reproduced", false)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_reproduce_timer += delta

	var creature := agent as CreatureAgent
	if not creature:
		return ExecResult.FAILURE

	# Consume energy for reproduction
	creature.energy = maxf(creature.energy - delta * 10.0, 0.0)
	agent.blackboard.set_value(&"energy", creature.energy)

	if _reproduce_timer >= _reproduce_duration:
		# Spawn offspring
		var ecosystem := creature.actor.get_parent() as Node
		if ecosystem and ecosystem.has_method("spawn_offspring"):
			ecosystem.spawn_offspring(creature)

		agent.blackboard.set_value(&"reproduced", true)
		agent.blackboard.set_value(&"can_reproduce", false)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_reproduce_timer = 0.0
