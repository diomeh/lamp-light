## Action: Defend current position.
extends GOAPAction
class_name DefendPositionAction

var _defend_timer: float = 0.0

func _init() -> void:
	action_name = &"DefendPosition"
	cost = 1.0
	preconditions = {}
	effects = {&"defending": true}

func enter(_agent: GOAPAgent) -> void:
	_defend_timer = 0.0

func execute(_agent: GOAPAgent, delta: float) -> ExecResult:
	_defend_timer += delta
	if _defend_timer >= 3.0:
		return ExecResult.SUCCESS
	return ExecResult.RUNNING
