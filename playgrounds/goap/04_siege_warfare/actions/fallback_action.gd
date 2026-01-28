## Action: Fall back from enemies (archer).
extends GOAPAction
class_name FallBackAction

func _init() -> void:
	action_name = &"FallBack"
	cost = 1.0
	preconditions = {&"enemies_in_melee_range": 1}
	effects = {&"safe_distance": true}

func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var unit := agent as UnitAgent
	if not unit:
		return ExecResult.FAILURE

	var enemies := unit.detect_enemies_in_range(30.0)
	if enemies.is_empty():
		agent.blackboard.set_value(&"safe_distance", true)
		return ExecResult.SUCCESS

	var closest := enemies[0]
	var flee_dir: Vector2 = (unit.actor.global_position - closest.actor.global_position).normalized()
	var target: Vector2 = unit.actor.global_position + flee_dir * 50.0
	unit.move_toward(target, delta, 1.2)

	return ExecResult.RUNNING
