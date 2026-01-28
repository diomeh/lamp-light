## Action: Issue advance order to troops.
extends GOAPAction
class_name IssueAdvanceAction

func _init() -> void:
	action_name = &"IssueAdvance"
	cost = 2.0
	preconditions = {}
	effects = {&"advance_ordered": true}

func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
	agent.blackboard.set_value(&"advance_ordered", true)
	return ExecResult.SUCCESS
