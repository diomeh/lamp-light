## Configurable mock goal for GOAP testing.
##
## Allows control over:[br]
## - Static or dynamic desired state[br]
## - Static or dynamic priority[br]
## - Relevance filtering[br]
## - Achievement tracking[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var mock := MockGoal.new()
## mock.goal_name = "TestGoal"
## mock.desired_state = {"has_item": true}
## mock.dynamic_priority = func(state): return 10.0 if state.get("urgent") else 1.0
## [/codeblock]
class_name MockGoal
extends GOAPGoal

## Callable for dynamic priority calculation.[br]
## Signature: [code]func(state: Dictionary) -> float[/code][br]
## If not set, uses static [member priority].
var dynamic_priority: Callable = Callable()

## Callable for dynamic desired state.[br]
## Signature: [code]func(state: Dictionary) -> Dictionary[/code][br]
## If not set, uses static [member desired_state].
var dynamic_desired_state: Callable = Callable()

## Callable for relevance check.[br]
## Signature: [code]func(state: Dictionary) -> bool[/code][br]
## If not set, always returns [code]true[/code].
var relevance_check: Callable = Callable()

## Force relevance to specific value (overrides relevance_check).
var force_relevant: Variant = null  # null = use relevance_check

## Tracks how many times after_plan_complete was called.
var completion_count: int = 0

## Callback invoked on plan completion.[br]
## Signature: [code]func(agent: GOAPAgent)[/code]
var on_complete: Callable = Callable()


func _init() -> void:
	goal_name = &"MockGoal"


## Resets tracking state for reuse.
func reset() -> void:
	completion_count = 0


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	if dynamic_priority.is_valid():
		return dynamic_priority.call(state)
	return priority


func get_desired_state(state: Dictionary[StringName, Variant]) -> Dictionary[StringName, Variant]:
	if dynamic_desired_state.is_valid():
		return dynamic_desired_state.call(state)
	return desired_state


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	if force_relevant != null:
		return force_relevant as bool
	if relevance_check.is_valid():
		return relevance_check.call(state)
	return true


func after_plan_complete(agent: GOAPAgent) -> void:
	completion_count += 1
	if on_complete.is_valid():
		on_complete.call(agent)


## Creates a simple mock goal with static configuration.[br][br]
##
## [param name] Goal identifier.[br]
## [param desires] Desired state conditions.[br]
## [param prio] Static priority value.[br]
## Returns configured [MockGoal].
static func create_simple(
	name: StringName,
	desires: Dictionary[StringName, Variant],
	prio: float = 1.0
) -> MockGoal:
	var mock := MockGoal.new()
	mock.goal_name = name
	mock.desired_state = desires
	mock.priority = prio
	return mock


## Creates a mock goal with dynamic priority.[br][br]
##
## [param name] Goal identifier.[br]
## [param desires] Desired state conditions.[br]
## [param priority_func] Callable returning priority from state.[br]
## Returns configured [MockGoal].
static func create_dynamic_priority(
	name: StringName,
	desires: Dictionary[StringName, Variant],
	priority_func: Callable
) -> MockGoal:
	var mock := MockGoal.new()
	mock.goal_name = name
	mock.desired_state = desires
	mock.dynamic_priority = priority_func
	return mock


## Creates a mock goal that is conditionally relevant.[br][br]
##
## [param name] Goal identifier.[br]
## [param desires] Desired state conditions.[br]
## [param relevant_when] Callable returning relevance from state.[br]
## Returns configured [MockGoal].
static func create_conditional(
	name: StringName,
	desires: Dictionary[StringName, Variant],
	relevant_when: Callable
) -> MockGoal:
	var mock := MockGoal.new()
	mock.goal_name = name
	mock.desired_state = desires
	mock.relevance_check = relevant_when
	return mock
