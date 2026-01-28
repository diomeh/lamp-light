## Action: Flee from nearby predator (herbivore).
##
## Moves away from detected threat at high speed.
extends GOAPAction
class_name FleeFromPredatorAction

var _flee_duration: float = 3.0
var _flee_timer: float = 0.0


func _init() -> void:
	action_name = &"FleeFromPredator"
	cost = 1.0  # Low cost - high priority action
	preconditions = {&"threat_detected": true}
	effects = {&"threat_detected": false}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"threat_detected", false) as bool


func enter(_agent: GOAPAgent) -> void:
	_flee_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_flee_timer += delta

	var creature := agent as CreatureAgent
	if not creature or not creature.detected_threat:
		return ExecResult.FAILURE

	# Move away from threat
	var threat_pos: Vector2 = creature.detected_threat.actor.global_position
	var flee_direction: Vector2 = (creature.actor.global_position - threat_pos).normalized()
	var target_pos: Vector2 = creature.actor.global_position + flee_direction * 200.0

	creature.move_toward(target_pos, delta * 1.5)  # 50% speed boost while fleeing

	# Consume extra energy while fleeing (panic)
	creature.energy = maxf(creature.energy - delta * 3.0, 0.0)
	agent.blackboard.set_value(&"energy", creature.energy)

	if _flee_timer >= _flee_duration:
		# Fled successfully
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_flee_timer = 0.0
