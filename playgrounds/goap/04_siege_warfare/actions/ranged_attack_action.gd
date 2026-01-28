## Action: Attack from range (archer).
extends GOAPAction
class_name RangedAttackAction

func _init() -> void:
	action_name = &"RangedAttack"
	cost = 1.5
	preconditions = {&"has_target": true}
	effects = {&"attacking": true}

func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var unit := agent as UnitAgent
	if not unit or not unit.target_enemy:
		return ExecResult.FAILURE

	var distance: float = unit.actor.global_position.distance_to(unit.target_enemy.actor.global_position)

	if distance > unit.attack_range:
		unit.move_toward(unit.target_enemy.actor.global_position, delta, 0.7)
		return ExecResult.RUNNING

	if unit.attack_unit(unit.target_enemy):
		agent.blackboard.set_value(&"attacking", true)

	return ExecResult.RUNNING
