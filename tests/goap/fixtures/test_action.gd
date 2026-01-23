extends GOAPAction
## Simple test action.

var _execute_count: int = 0

func _init() -> void:
	action_name = &"TestAction"
	effects = {&"test_complete": true}

func execute(_agent: GOAPAgent, _delta: float) -> ExecResult:
	_execute_count += 1
	return ExecResult.SUCCESS
