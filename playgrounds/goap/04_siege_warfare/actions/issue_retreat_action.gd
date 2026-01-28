## Action: Issue retreat order to troops.
extends GOAPAction
class_name IssueRetreatAction

func _init() -> void:
	action_name = &"IssueRetreat"
	cost = 1.0
	preconditions = {}
	effects = {&"retreat_ordered": true}

func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
	agent.blackboard.set_value(&"retreat_ordered", true)
	return ExecResult.SUCCESS
