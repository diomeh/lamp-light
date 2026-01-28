## Action: Assign formation positions to units.
extends GOAPAction
class_name AssignFormationAction

func _init() -> void:
	action_name = &"AssignFormation"
	cost = 2.0
	preconditions = {}
	effects = {&"troops_commanded": true}

func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
	var commander := agent as Commander
	if not commander:
		return ExecResult.FAILURE

	var units := commander.get_commanded_units()
	for i in range(units.size()):
		var unit := units[i]
		var offset := Vector2(i * 20.0, 0)
		unit.assign_formation(commander.actor.global_position + offset, commander)

	agent.blackboard.set_value(&"troops_commanded", true)
	return ExecResult.SUCCESS
