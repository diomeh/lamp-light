## Action: Operate siege catapult.
extends GOAPAction
class_name OperateCatapultAction

func _init() -> void:
	action_name = &"OperateCatapult"
	cost = 3.0
	preconditions = {&"siege_equipment_available": true}
	effects = {&"operating_equipment": true}

func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
	agent.blackboard.set_value(&"operating_equipment", true)
	return ExecResult.RUNNING
