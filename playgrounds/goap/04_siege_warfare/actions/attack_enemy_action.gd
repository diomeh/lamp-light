## Action: Attack nearby enemy unit.
extends GOAPAction
class_name AttackEnemyAction

func _init() -> void:
	action_name = &"AttackEnemy"
	cost = 2.0
	preconditions = {&"has_target": true}
	effects = {&"in_combat": true}

func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"has_target", false) and not state.get(&"is_dead", false)

func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var unit := agent as UnitAgent
	if not unit or not unit.target_enemy:
		return ExecResult.FAILURE

	var distance := unit.move_toward(unit.target_enemy.actor.global_position, delta)
	if distance <= unit.attack_range:
		if unit.attack_unit(unit.target_enemy):
			agent.blackboard.set_value(&"in_combat", true)
		return ExecResult.RUNNING

	if distance < unit.attack_range * 1.2:
		return ExecResult.RUNNING
	return ExecResult.SUCCESS
