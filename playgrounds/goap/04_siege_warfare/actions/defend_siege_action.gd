## Action: Defend siege equipment.
extends GOAPAction
class_name DefendSiegeAction

func _init() -> void:
	action_name = &"DefendSiege"
	cost = 2.0
	preconditions = {}
	effects = {&"equipment_defended": true}

func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
	agent.blackboard.set_value(&"equipment_defended", true)
	return ExecResult.RUNNING
