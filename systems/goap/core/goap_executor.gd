## Executes GOAP action plans sequentially.
##
## Manages action lifecycle (enter/execute/exit) and reports completion status.[br]
## Extracted from GOAPAgent for single responsibility and testability.[br][br]
##
## [b]Lifecycle:[/b][br]
## [codeblock]
## start(plan)
##     │
##     ▼
## ┌─► tick() ─► action.enter() (first call)
## │      │
## │      ▼
## │   action.execute()
## │      │
## │      ├─► RUNNING ─► loop back
## │      ├─► SUCCESS ─► action.exit() ─► next action or complete
## │      └─► FAILURE ─► action.exit() ─► abort
## [/codeblock]
## [br]
## See also: [GOAPAgent], [GOAPAction]
class_name GOAPExecutor
extends RefCounted

## Emitted when all actions complete successfully.
signal plan_completed

## Emitted when an action fails.[br]
## [param action] The action that failed.
signal plan_failed(action: GOAPAction)

## Emitted when an action begins executing.[br]
## [param action] The action starting.
signal action_started(action: GOAPAction)

## Emitted when an action finishes (success or failure).[br]
## [param action] The action that ended.[br]
## [param result] The execution result.
signal action_ended(action: GOAPAction, result: GOAPAction.ExecResult)

## Current plan being executed.
var _plan: Array[GOAPAction] = []

## Index of current action in plan.
var _current_index: int = -1

## Action currently executing.
var _current_action: GOAPAction = null

## Whether executor is running a plan.
var _is_running: bool = false

## Whether current action has been entered.
var _action_entered: bool = false


## Returns true if executor is currently running a plan.
func is_running() -> bool:
	return _is_running


## Returns the currently executing action, or null.
func get_current_action() -> GOAPAction:
	return _current_action


## Returns current position in plan (0-indexed).
func get_current_index() -> int:
	return _current_index


## Returns total actions in current plan.
func get_plan_size() -> int:
	return _plan.size()


## Starts executing a new plan.[br][br]
##
## Aborts any existing plan. Empty plans complete immediately.[br][br]
##
## [param plan] Array of actions to execute in order.
func start(plan: Array[GOAPAction]) -> void:
	abort()

	_plan = plan
	_current_index = 0
	_current_action = null
	_action_entered = false

	if _plan.is_empty():
		plan_completed.emit()
		return

	_is_running = true


## Advances plan execution by one frame.[br][br]
##
## Call this every frame while executor is running.[br][br]
##
## [param agent] Agent performing the actions.[br]
## [param delta] Time since last frame.
func tick(agent: GOAPAgent, delta: float) -> void:
	if not _is_running:
		return

	# Start next action if needed
	if _current_action == null:
		if _current_index >= _plan.size():
			_complete()
			return

		_current_action = _plan[_current_index]
		_action_entered = false

	# Enter action on first tick
	if not _action_entered:
		_current_action.enter(agent)
		_action_entered = true
		action_started.emit(_current_action)

	# Execute action
	var result := _current_action.execute(agent, delta)

	match result:
		GOAPAction.ExecResult.SUCCESS:
			_finish_action(agent, result)
			_advance()
		GOAPAction.ExecResult.FAILURE:
			_finish_action(agent, result)
			_fail()
		GOAPAction.ExecResult.RUNNING:
			pass


## Aborts current plan immediately.[br][br]
##
## Calls exit on current action if one is running.[br]
## Does not emit signals.[br][br]
##
## [param agent] Agent to pass to action.exit(). Optional.
func abort(agent: GOAPAgent = null) -> void:
	if _current_action and _action_entered and agent:
		_current_action.exit(agent)

	_reset()


## Finishes current action and emits signal.
func _finish_action(agent: GOAPAgent, result: GOAPAction.ExecResult) -> void:
	_current_action.exit(agent)
	action_ended.emit(_current_action, result)


## Advances to next action in plan.
func _advance() -> void:
	_current_action = null
	_action_entered = false
	_current_index += 1


## Completes plan successfully.
func _complete() -> void:
	_reset()
	plan_completed.emit()


## Fails plan at current action.
func _fail() -> void:
	var failed_action := _current_action
	_reset()
	plan_failed.emit(failed_action)


## Resets executor to idle state.
func _reset() -> void:
	_plan.clear()
	_current_index = -1
	_current_action = null
	_action_entered = false
	_is_running = false