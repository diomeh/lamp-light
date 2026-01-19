## Test helper utilities for GOAP system tests.
##
## Provides factory methods, validation utilities, and common test patterns[br]
## to reduce boilerplate in test suites.[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var helper := GOAPTestHelper.new()
## var action := helper.create_action("TestAction", {"has_item": true}, {"task_done": true})
## var goal := helper.create_goal("TestGoal", {"task_done": true}, 5.0)
## [/codeblock]
class_name GOAPTestHelper
extends RefCounted


## Creates a GOAPState with initial data.[br][br]
##
## [param initial_data] Dictionary of key-value pairs to populate state.[br]
## Returns configured [GOAPState] instance.
static func create_state(initial_data: Dictionary[StringName, Variant] = {}) -> GOAPState:
	return GOAPState.new(initial_data)


## Creates a configured GOAPAction for testing.[br][br]
##
## [param name] Action identifier.[br]
## [param preconditions] Required conditions to execute.[br]
## [param effects] State changes produced by action.[br]
## [param cost] Planning cost (default 1.0).[br]
## Returns configured [GOAPAction] instance.
static func create_action(
	name: StringName,
	preconditions: Dictionary[StringName, Variant] = {},
	effects: Dictionary[StringName, Variant] = {},
	cost: float = 1.0
) -> GOAPAction:
	var action := GOAPAction.new()
	action.action_name = name
	action.preconditions = preconditions
	action.effects = effects
	action.cost = cost
	return action


## Creates a configured GOAPGoal for testing.[br][br]
##
## [param name] Goal identifier.[br]
## [param desired_state] Conditions that define goal achievement.[br]
## [param priority] Goal priority (default 1.0).[br]
## Returns configured [GOAPGoal] instance.
static func create_goal(
	name: StringName,
	desired_state: Dictionary[StringName, Variant] = {},
	priority: float = 1.0
) -> GOAPGoal:
	var goal := GOAPGoal.new()
	goal.goal_name = name
	goal.desired_state = desired_state
	goal.priority = priority
	return goal


## Verifies that a plan achieves the specified goal from the given state.[br][br]
##
## Simulates plan execution by applying each action's effects in sequence,
## then checks if goal conditions are satisfied.[br][br]
##
## [param plan] Array of actions to verify.[br]
## [param initial_state] Starting state before plan execution.[br]
## [param goal] Goal that plan should achieve.[br]
## Returns [code]true[/code] if simulated execution achieves goal.
static func verify_plan_achieves_goal(
	plan: Array[GOAPAction],
	initial_state: GOAPState,
	goal: GOAPGoal
) -> bool:
	var simulated_state := initial_state.duplicate()

	for action in plan:
		# Check preconditions are met
		if not simulated_state.matches_conditions(action.preconditions):
			return false
		# Apply effects
		simulated_state.apply_effects(action.effects)

	return goal.is_achieved(simulated_state.to_ref())


## Calculates total cost of a plan.[br][br]
##
## [param plan] Array of actions to sum costs for.[br]
## Returns total accumulated cost.
static func calculate_plan_cost(plan: Array[GOAPAction]) -> float:
	var total: float = 0.0
	for action in plan:
		total += action.cost
	return total


## Creates a minimal GOAPAgent for testing (requires scene tree).[br][br]
##
## [param blackboard] Initial blackboard state.[br]
## [param actions] Available actions.[br]
## [param goals] Available goals.[br]
## Returns configured [GOAPAgent] instance.
static func create_agent(
	blackboard: GOAPState = null,
	actions: Array[GOAPAction] = [],
	goals: Array[GOAPGoal] = []
) -> GOAPAgent:
	var agent := GOAPAgent.new(blackboard, actions, goals)
	return agent


## Waits for a signal with timeout.[br][br]
##
## [param obj] Object emitting the signal.[br]
## [param signal_name] Name of signal to wait for.[br]
## [param timeout_seconds] Maximum wait time.[br]
## Returns [code]true[/code] if signal received, [code]false[/code] on timeout.
static func wait_for_signal_or_timeout(
	obj: Object,
	signal_name: StringName,
	timeout_seconds: float
) -> bool:
	var received := {"value": false}
	var callback := func(): received.value = true

	obj.connect(signal_name, callback, CONNECT_ONE_SHOT)

	var start := Time.get_ticks_msec()
	var timeout_ms := int(timeout_seconds * 1000.0)

	while not received.value:
		if Time.get_ticks_msec() - start > timeout_ms:
			if obj.is_connected(signal_name, callback):
				obj.disconnect(signal_name, callback)
			return false
		await Engine.get_main_loop().process_frame

	return true
