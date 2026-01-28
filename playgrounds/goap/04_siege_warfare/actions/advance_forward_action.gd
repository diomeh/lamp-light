## Action: Advance toward objective.
extends GOAPAction
class_name AdvanceForwardAction

var _advance_target: Vector2 = Vector2.ZERO

func _init() -> void:
	action_name = &"AdvanceForward"
	cost = 2.0
	preconditions = {}
	effects = {&"advancing": true}

func enter(agent: GOAPAgent) -> void:
	var unit := agent as UnitAgent
	if unit and unit.army == UnitAgent.Army.ATTACKER:
		_advance_target = Vector2(750, 300)  # Toward defender base
	else:
		_advance_target = Vector2(250, 300)  # Toward attacker base

func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var unit := agent as UnitAgent
	if not unit:
		return ExecResult.FAILURE

	var distance := unit.move_toward(_advance_target, delta, 0.8)
	if distance < 20.0:
		agent.blackboard.set_value(&"advancing", true)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING
