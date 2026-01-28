## Action: Find nearest corpse (scavenger).
##
## Moves toward detected corpse location.
extends GOAPAction
class_name FindCorpseAction

var _search_timer: float = 0.0


func _init() -> void:
	action_name = &"FindCorpse"
	cost = 2.0
	preconditions = {&"corpse_detected": true}
	effects = {&"at_corpse": true}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"corpse_detected", false) as bool


func enter(agent: GOAPAgent) -> void:
	_search_timer = 0.0
	agent.blackboard.set_value(&"at_corpse", false)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_search_timer += delta

	var creature := agent as CreatureAgent
	if not creature:
		return ExecResult.FAILURE

	var corpse_pos := agent.blackboard.get_value(&"corpse_position", Vector2.ZERO) as Vector2
	var distance := creature.move_toward(corpse_pos, delta)

	# Consume energy while moving
	creature.energy = maxf(creature.energy - delta * 1.5, 0.0)
	agent.blackboard.set_value(&"energy", creature.energy)

	if distance < 15.0:
		agent.blackboard.set_value(&"at_corpse", true)
		return ExecResult.SUCCESS

	if _search_timer > 8.0:
		# Corpse might have been consumed by another scavenger
		return ExecResult.FAILURE

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_search_timer = 0.0
