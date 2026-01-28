## Action: Idle when no work available.
##
## Fallback action - does nothing.
extends GOAPAction
class_name IdleAction

var _idle_timer: float = 0.0
var _idle_duration: float = 3.0


func _init() -> void:
	action_name = &"Idle"
	cost = 0.5
	preconditions = {}
	effects = {&"idle": true}


func can_execute(_state: Dictionary[StringName, Variant]) -> bool:
	return true


func enter(agent: GOAPAgent) -> void:
	_idle_timer = 0.0
	agent.blackboard.set_value(&"idle", false)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_idle_timer += delta

	if _idle_timer >= _idle_duration:
		agent.blackboard.set_value(&"idle", true)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_idle_timer = 0.0
