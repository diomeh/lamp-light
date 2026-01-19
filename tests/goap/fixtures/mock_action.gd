## Configurable mock action for GOAP testing.
##
## Allows fine-grained control over action behavior including:[br]
## - Success/failure outcomes[br]
## - Execution delay (frame count)[br]
## - Callbacks on lifecycle events[br]
## - State modifications[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var mock := MockAction.new()
## mock.action_name = "TestAction"
## mock.mock_result = GOAPAction.ExecResult.SUCCESS
## mock.execute_frames = 3  # Takes 3 frames to complete
## mock.on_execute = func(agent): print("Executing!")
## [/codeblock]
class_name MockAction
extends GOAPAction

## Result to return from execute() after delay.[br]
## Set to RUNNING to keep action executing indefinitely.
var mock_result: ExecResult = ExecResult.SUCCESS

## Number of frames to return RUNNING before final result.[br]
## 0 = immediate completion.
var execute_frames: int = 0

## Callback invoked on enter(). Signature: [code]func(agent: GOAPAgent)[/code]
var on_enter: Callable = Callable()

## Callback invoked each execute() frame. Signature: [code]func(agent: GOAPAgent)[/code]
var on_execute: Callable = Callable()

## Callback invoked on exit(). Signature: [code]func(agent: GOAPAgent)[/code]
var on_exit: Callable = Callable()

## State modifications to apply on success.[br]
## Applied after successful execution completes.
var state_modifications: Dictionary[StringName, Variant] = {}

## Tracks whether enter() was called.
var enter_called: bool = false

## Tracks number of execute() calls.
var execute_call_count: int = 0

## Tracks whether exit() was called.
var exit_called: bool = false

## Internal frame counter for delayed execution.
var _frames_executed: int = 0


func _init() -> void:
	action_name = &"MockAction"


## Resets all tracking state for reuse.[br][br]
##
## Call between tests to ensure clean state.
func reset() -> void:
	enter_called = false
	execute_call_count = 0
	exit_called = false
	_frames_executed = 0


func enter(agent: GOAPAgent) -> void:
	enter_called = true
	if on_enter.is_valid():
		on_enter.call(agent)


func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
	execute_call_count += 1

	if on_execute.is_valid():
		on_execute.call(agent)

	_frames_executed += 1

	if _frames_executed <= execute_frames:
		return ExecResult.RUNNING

	# Apply state modifications on success
	if mock_result == ExecResult.SUCCESS and not state_modifications.is_empty():
		agent.blackboard.apply_effects(state_modifications)

	return mock_result


func exit(agent: GOAPAgent) -> void:
	exit_called = true
	if on_exit.is_valid():
		on_exit.call(agent)


## Creates a pre-configured mock that succeeds immediately.[br][br]
##
## [param name] Action name.[br]
## [param precond] Required conditions.[br]
## [param eff] State changes on success.[br]
## Returns configured [MockAction].
static func create_succeeding(
	name: StringName,
	precond: Dictionary[StringName, Variant] = {},
	eff: Dictionary[StringName, Variant] = {}
) -> MockAction:
	var mock := MockAction.new()
	mock.action_name = name
	mock.preconditions = precond
	mock.effects = eff
	mock.mock_result = ExecResult.SUCCESS
	mock.state_modifications = eff
	return mock


## Creates a pre-configured mock that fails immediately.[br][br]
##
## [param name] Action name.[br]
## [param precond] Required conditions.[br]
## Returns configured [MockAction].
static func create_failing(
	name: StringName,
	precond: Dictionary[StringName, Variant] = {}
) -> MockAction:
	var mock := MockAction.new()
	mock.action_name = name
	mock.preconditions = precond
	mock.mock_result = ExecResult.FAILURE
	return mock


## Creates a pre-configured mock with delayed completion.[br][br]
##
## [param name] Action name.[br]
## [param frames] Number of frames before completion.[br]
## [param result] Final result after delay.[br]
## Returns configured [MockAction].
static func create_delayed(
	name: StringName,
	frames: int,
	result: ExecResult = ExecResult.SUCCESS
) -> MockAction:
	var mock := MockAction.new()
	mock.action_name = name
	mock.execute_frames = frames
	mock.mock_result = result
	return mock
