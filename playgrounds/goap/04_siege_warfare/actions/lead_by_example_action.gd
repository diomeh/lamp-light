## Action: Lead troops by example.
extends GOAPAction
class_name LeadByExampleAction

func _init() -> void:
	action_name = &"LeadByExample"
	cost = 2.5
	preconditions = {}
	effects = {&"leading_charge": true}

func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
	agent.blackboard.set_value(&"leading_charge", true)
	return ExecResult.RUNNING
