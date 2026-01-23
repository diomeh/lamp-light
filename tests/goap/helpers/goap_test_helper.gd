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


## Creates a MockAction with full configuration including state modifications.
static func create_mock_action(
	name: StringName,
	preconditions: Dictionary[StringName, Variant] = {},
	effects: Dictionary[StringName, Variant] = {},
	cost: float = 1.0
) -> MockAction:
	var mock := MockAction.new()
	mock.action_name = name
	mock.preconditions = preconditions
	mock.effects = effects
	mock.cost = cost
	mock.state_modifications = effects
	mock.mock_result = GOAPAction.ExecResult.SUCCESS
	return mock


## Creates a MockGoal with full configuration.
static func create_mock_goal(
	name: StringName,
	desired_state: Dictionary[StringName, Variant],
	priority: float = 1.0
) -> MockGoal:
	var mock := MockGoal.new()
	mock.goal_name = name
	mock.desired_state = desired_state
	mock.priority = priority
	return mock


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


# =============================================================================
# BENCHMARK UTILITIES
# =============================================================================

## Runs a function multiple times and returns timing statistics.[br][br]
##
## [param func_to_test] Callable to benchmark.[br]
## [param iterations] Number of times to run (default 100).[br]
## Returns dictionary with timing statistics.
static func benchmark_function(
	func_to_test: Callable,
	iterations: int = 100
) -> Dictionary:
	var times: Array[float] = []
	for i in range(iterations):
		var start := Time.get_ticks_usec()
		func_to_test.call()
		var elapsed := (Time.get_ticks_usec() - start) / 1000.0  # Convert to ms
		times.append(elapsed)

	times.sort()

	return {
		&"iterations": iterations,
		&"total_ms": times[-1] if times else 0.0,
		&"avg_ms": times[times.size() / 2.0] if times else 0.0,
		&"min_ms": times[0] if times else 0.0,
		&"max_ms": times[-1] if times else 0.0
	}


## Benchmarks a planning call with the given parameters.[br][br]
##
## [param state] Initial state.[br]
## [param actions] Available actions.[br]
## [param goal] Goal to plan for.[br]
## [param iterations] Number of planning runs.[br]
## Returns timing statistics for the planning calls.
static func benchmark_plan(
	state: GOAPState,
	actions: Array[GOAPAction],
	goal: GOAPGoal,
	iterations: int = 50
) -> Dictionary:
	return benchmark_function(func():
		GOAPPlanner.plan(state, actions, goal)
	, iterations)


# =============================================================================
# SCENE RUNNER UTILITIES
# =============================================================================

## Creates a test scene with agent + orchestrator.[br][br]
##
## [param agent_config] Optional configuration for the agent.[br]
## Returns root node of created scene.
static func create_test_scene(agent_config: Dictionary = {}) -> Node:
	var scene := Node.new()
	scene.name = &"TestScene"

	var orch: GOAPOrchestrator = GOAPOrchestrator.new()
	orch.name = &"Orchestrator"
	scene.add_child(orch)

	var agent := GOAPAgent.new()
	agent.name = &"Agent"

	if agent_config.has(&"blackboard"):
		agent.blackboard = agent_config[&"blackboard"]
	if agent_config.has(&"actions"):
		agent.actions = agent_config[&"actions"]
	if agent_config.has(&"goals"):
		agent.goals = agent_config[&"goals"]

	scene.add_child(agent)
	return scene


## Waits for agent state change with timeout.[br][br]
##
## [param agent] Agent to monitor.[br]
## [param target_state] State to wait for.[br]
## [param timeout_seconds] Maximum wait time.[br]
## Returns [code]true[/code] if state reached, [code]false[/code] on timeout.
static func wait_for_state(
	agent: GOAPAgent,
	target_state: GOAPAgent.State,
	timeout_seconds: float = 5.0
) -> bool:
	var start := Time.get_ticks_msec()
	var timeout_ms := int(timeout_seconds * 1000.0)

	while agent.get_state() != target_state:
		if Time.get_ticks_msec() - start > timeout_ms:
			return false
		await Engine.get_main_loop().process_frame

	return true


## Simulates a number of frames and advances time.[br][br]
##
## [param frame_count] Number of frames to simulate.[br]
## [param delta] Time per frame (default 0.016 = 60fps).[br]
## Returns after specified frames have elapsed.
static func simulate_frames(frame_count: int, _delta: float = 0.016) -> void:
	for i in range(frame_count):
		await Engine.get_main_loop().process_frame
		await Engine.get_main_loop().physics_process_frame


# =============================================================================
# ASSERTION HELPERS
# =============================================================================

## Asserts that a plan has expected properties.[br][br]
##
## [param plan] Plan to validate.[br]
## [param expected_size] Expected number of actions.[br]
## [param expected_cost] Expected total cost (optional).[br]
## [param expected_first_action] Name of expected first action (optional).[br]
## Returns [code]true[/code] if all validations pass.
static func assert_plan_valid(
	plan: Array[GOAPAction],
	expected_size: int,
	expected_cost: float = -1.0,
	expected_first_action: StringName = &""
) -> bool:
	if plan.size() != expected_size:
		return false

	if expected_cost >= 0.0:
		if not is_equal_approx(calculate_plan_cost(plan), expected_cost):
			return false

	if expected_first_action != &"":
		if plan.is_empty() or plan[0].action_name != expected_first_action:
			return false

	return true


## Asserts that all actions in plan have valid preconditions for execution order.[br][br]
##
## [param plan] Plan to validate.[br]
## [param initial_state] Starting state before plan execution.[br]
## Returns [code]true[/code] if all preconditions are met in sequence.
static func assert_plan_executable(
	plan: Array[GOAPAction],
	initial_state: GOAPState
) -> bool:
	var current_state := initial_state.duplicate()

	for action in plan:
		if not current_state.matches_conditions(action.preconditions):
			return false
		current_state.apply_effects(action.effects)

	return true
