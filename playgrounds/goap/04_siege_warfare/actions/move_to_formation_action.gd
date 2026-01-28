## Action: Move to assigned formation position.
extends GOAPAction
class_name MoveToFormationAction

func _init() -> void:
	action_name = &"MoveToFormation"
	cost = 1.5
	preconditions = {&"has_formation": true}
	effects = {&"in_formation": true}

func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var unit := agent as UnitAgent
	if not unit:
		return ExecResult.FAILURE

	var distance := unit.move_toward(unit.formation_position, delta)
	if distance < 5.0:
		unit.enter_formation()
		return ExecResult.SUCCESS

	return ExecResult.RUNNING
