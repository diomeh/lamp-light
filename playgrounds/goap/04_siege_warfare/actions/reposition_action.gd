## Action: Reposition for better angle.
extends GOAPAction
class_name RepositionAction

var _reposition_timer: float = 0.0

func _init() -> void:
	action_name = &"Reposition"
	cost = 1.0
	preconditions = {}
	effects = {&"at_optimal_range": true}

func enter(_agent: GOAPAgent) -> void:
	_reposition_timer = 0.0

func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_reposition_timer += delta
	if _reposition_timer >= 2.0:
		agent.blackboard.set_value(&"at_optimal_range", true)
		return ExecResult.SUCCESS
	return ExecResult.RUNNING
