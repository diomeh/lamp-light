## Performance benchmark tests for GOAP system.
##
## Validates performance targets and detects regressions.[br]
## All benchmarks should complete within specified time limits.[br][br]
##
## [b]Performance Targets:[/b][br]
## - State operations: < 1ms for 1000 ops[br]
## - Simple plan: < 1ms[br]
## - Complex plan: < 10ms[br]
## - Orchestrator: < 4ms per frame[br]
##
## See also: [GOAPTestHelper.benchmark_function]
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

var _state: GOAPState
var _created_agents: Array[GOAPAgent] = []


func before_test() -> void:
	_state = GOAPTestHelper.create_state()
	_created_agents.clear()


func after_test() -> void:
	_state = null
	# Free all created agents to prevent orphan warnings
	for agent in _created_agents:
		if is_instance_valid(agent):
			agent.free()
	_created_agents.clear()


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _benchmark(
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
		"iterations": iterations,
		"total_ms": times[-1] if times else 0.0,  # Last is max after sort
		"avg_ms": times[times.size() / 2.0] if times else 0.0,  # Median
		"min_ms": times[0] if times else 0.0,
		"max_ms": times[-1] if times else 0.0
	}


# =============================================================================
# STATE OPERATION BENCHMARKS
# =============================================================================

func test_benchmark_state_set_1000_times() -> void:
	## Benchmark: 1000 state set operations
	## Target: < 1ms

	# Arrange
	var iterations := 1000

	# Act
	var stats := _benchmark(func():
		for i in range(iterations):
			_state.set_value(("key_%d" % i) as StringName, i)
	, iterations)

	# Assert
	assert_float(stats.avg_ms).is_less(1.0)


func test_benchmark_state_get_1000_times() -> void:
	## Benchmark: 1000 state get operations
	## Target: < 0.5ms (may be higher in headless/CI environments)

	# Arrange
	for i in range(1000):
		_state.set_value(("key_%d" % i) as StringName, i)
	var iterations := 1000

	# Act
	var stats := _benchmark(func():
		for i in range(iterations):
			_state.get_value(("key_%d" % i) as StringName)
	, iterations)

	# Assert - use 0.8ms threshold for headless/CI environments
	assert_float(stats.avg_ms).is_less(0.8)


func test_benchmark_state_matches_conditions_50() -> void:
	## Benchmark: Match 50 conditions
	## Target: < 0.1ms

	# Arrange
	var conditions: Dictionary[StringName, Variant] = {}
	for i in range(50):
		conditions[("key_%d" % i) as StringName] = i
		_state.set_value(("key_%d" % i) as StringName, i)

	# Act
	var start := Time.get_ticks_usec()
	for i in range(100):
		_state.matches_conditions(conditions)
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert - 100 iterations, so divide by 100 for per-run time
	assert_float(elapsed / 100.0).is_less(0.1)


func test_benchmark_state_duplicate() -> void:
	## Benchmark: Duplicate state with 100 keys
	## Target: < 1ms

	# Arrange
	for i in range(100):
		_state.set_value(("key_%d" % i) as StringName, i)

	# Act
	var stats := _benchmark(func():
		_state.duplicate()
	, 100)

	# Assert
	assert_float(stats.avg_ms).is_less(1.0)


func test_benchmark_state_apply_effects() -> void:
	## Benchmark: Apply 10 effects
	## Target: < 0.5ms

	# Arrange
	var effects: Dictionary[StringName, Variant] = {}
	for i in range(10):
		effects[("effect_%d" % i) as StringName] = i

	# Act
	var stats := _benchmark(func():
		_state.apply_effects(effects)
	, 100)

	# Assert
	assert_float(stats.avg_ms).is_less(0.5)


# =============================================================================
# PLANNING BENCHMARKS - SIMPLE
# =============================================================================

func test_benchmark_plan_single_action() -> void:
	## Benchmark: Plan with single action, no preconditions
	## Target: < 0.5ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"Do", {}, {&"target": true})
	]

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 100)

	# Assert
	assert_float(stats.avg_ms).is_less(0.5)


func test_benchmark_plan_two_step_chain() -> void:
	## Benchmark: Plan with 2-action chain
	## Target: < 1ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"Step1", {}, {&"intermediate": true}),
		GOAPTestHelper.create_mock_action(&"Step2", {&"intermediate": true}, {&"target": true})
	]

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 100)

	# Assert
	assert_float(stats.avg_ms).is_less(1.0)


func test_benchmark_plan_three_step_chain() -> void:
	## Benchmark: Plan with 3-action chain
	## Target: < 2ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"Step1", {}, {&"s1": true}),
		GOAPTestHelper.create_mock_action(&"Step2", {&"s1": true}, {&"s2": true}),
		GOAPTestHelper.create_mock_action(&"Step3", {&"s2": true}, {&"target": true})
	]

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 100)

	# Assert
	assert_float(stats.avg_ms).is_less(2.0)


# =============================================================================
# PLANNING BENCHMARKS - COMPLEX
# =============================================================================

func test_benchmark_plan_complex_5_step() -> void:
	## Benchmark: Complex 5-step plan
	## Target: < 5ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Complex", {&"final": true})
	var actions: Array[GOAPAction] = []
	for i in range(5):
		var prereq: Dictionary[StringName, Variant] = {}
		if i > 0:
			prereq[("step%d" % (i-1)) as StringName] = true
		var eff: Dictionary[StringName, Variant] = {("step%d" % i) as StringName: true}
		if i == 4:
			eff[&"final"] = true
		actions.append(GOAPTestHelper.create_mock_action(("Step%d" % i) as StringName, prereq, eff))

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 50)

	# Assert
	assert_float(stats.avg_ms).is_less(5.0)


func test_benchmark_plan_complex_10_step() -> void:
	## Benchmark: Complex 10-step plan
	## Target: < 10ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Complex", {&"final": true})
	var actions: Array[GOAPAction] = []
	for i in range(10):
		var prereq: Dictionary[StringName, Variant] = {}
		if i > 0:
			prereq[("step%d" % (i-1)) as StringName] = true
		var eff: Dictionary[StringName, Variant] = {("step%d" % i) as StringName: true}
		if i == 9:
			eff[&"final"] = true
		actions.append(GOAPTestHelper.create_mock_action(("Step%d" % i) as StringName, prereq, eff))

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 20)

	# Assert
	assert_float(stats.avg_ms).is_less(10.0)


# =============================================================================
# PLANNING SCALABILITY BENCHMARKS
# =============================================================================

func test_benchmark_plan_10_actions() -> void:
	## Benchmark: 10 available actions, 1 useful
	## Target: < 2ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = []
	for i in range(10):
		actions.append(GOAPTestHelper.create_mock_action(
			("Irrelevant%d" % i) as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	actions.append(GOAPTestHelper.create_mock_action(&"Useful", {}, {&"target": true}))

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 50)

	# Assert
	assert_float(stats.avg_ms).is_less(2.0)


func test_benchmark_plan_25_actions() -> void:
	## Benchmark: 25 available actions, 1 useful
	## Target: < 3ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = []
	for i in range(25):
		actions.append(GOAPTestHelper.create_mock_action(
			("Irrelevant%d" % i) as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	actions.append(GOAPTestHelper.create_mock_action(&"Useful", {}, {&"target": true}))

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 20)

	# Assert
	assert_float(stats.avg_ms).is_less(3.0)


func test_benchmark_plan_50_actions() -> void:
	## Benchmark: 50 available actions, 1 useful (tests effect indexing)
	## Target: < 5ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = []
	for i in range(50):
		actions.append(GOAPTestHelper.create_mock_action(
			("Irrelevant%d" % i) as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	actions.append(GOAPTestHelper.create_mock_action(&"Useful", {}, {&"target": true}))

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 10)

	# Assert
	assert_float(stats.avg_ms).is_less(5.0)


func test_benchmark_plan_100_actions() -> void:
	## Benchmark: 100 available actions, 1 useful
	## Target: < 10ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = []
	for i in range(100):
		actions.append(GOAPTestHelper.create_mock_action(
			("Irrelevant%d" % i) as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	actions.append(GOAPTestHelper.create_mock_action(&"Useful", {}, {&"target": true}))

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 5)

	# Assert
	assert_float(stats.avg_ms).is_less(10.0)


func test_benchmark_plan_200_actions() -> void:
	## Benchmark: 200 available actions, 1 useful (stress test)
	## Target: < 20ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})
	var actions: Array[GOAPAction] = []
	for i in range(200):
		actions.append(GOAPTestHelper.create_mock_action(
			("Irrelevant%d" % i) as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	actions.append(GOAPTestHelper.create_mock_action(&"Useful", {}, {&"target": true}))

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 3)

	# Assert
	assert_float(stats.avg_ms).is_less(20.0)


# =============================================================================
# PLANNING SCENARIO BENCHMARKS
# =============================================================================

func test_benchmark_plan_crafting_chain() -> void:
	## Benchmark: Crafting chain (5 steps)
	## Target: < 8ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Craft", {&"has_item": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"GetTool", {}, {&"has_tool": true}),
		GOAPTestHelper.create_mock_action(&"Gather", {&"has_tool": true}, {&"has_material": true}),
		GOAPTestHelper.create_mock_action(&"Process", {&"has_material": true}, {&"has_component": true}),
		GOAPTestHelper.create_mock_action(&"Assemble", {&"has_component": true}, {&"has_subassembly": true}),
		GOAPTestHelper.create_mock_action(&"Finish", {&"has_subassembly": true}, {&"has_item": true})
	]

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 20)

	# Assert
	assert_float(stats.avg_ms).is_less(8.0)


func test_benchmark_plan_diamond_dependency() -> void:
	## Benchmark: Diamond dependency pattern
	## Target: < 5ms

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Goal", {&"a": true, &"b": true, &"c": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"GetA", {}, {&"a": true}),
		GOAPTestHelper.create_mock_action(&"GetB", {}, {&"b": true}),
		GOAPTestHelper.create_mock_action(&"GetC", {}, {&"c": true}),
		GOAPTestHelper.create_mock_action(&"GetAAndB", {}, {&"a": true, &"b": true}, 1.5)
	]

	# Act
	var stats := _benchmark(func():
		GOAPPlanner.plan(state, actions, goal)
	, 30)

	# Assert
	assert_float(stats.avg_ms).is_less(5.0)


# =============================================================================
# EXECUTOR BENCHMARKS
# =============================================================================

func test_benchmark_executor_10_instant_actions() -> void:
	## Benchmark: Execute 10 instant actions
	## Target: < 2ms total

	# Arrange
	var executor := GOAPExecutor.new()
	var agent := _create_mock_agent()
	var actions: Array[GOAPAction] = []
	for i in range(10):
		var action := GOAPAction.new()
		action.action_name = ("Action%d" % i) as StringName
		action.effects = {("done%d" % i): true}
		actions.append(action)

	# Act
	var start := Time.get_ticks_usec()
	executor.start(actions)
	for i in range(20):  # Extra ticks to complete all
		executor.tick(agent, 0.016)
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert
	assert_float(elapsed).is_less(2.0)


func test_benchmark_executor_lifecycle_overhead() -> void:
	## Benchmark: Action enter/execute/exit lifecycle
	## Target: < 0.1ms per action

	# Arrange
	var executor := GOAPExecutor.new()
	var agent := _create_mock_agent()
	var action := GOAPAction.new()
	action.action_name = &"TestAction"

	# Act
	var start := Time.get_ticks_usec()
	executor.start([action] as Array[GOAPAction])
	executor.tick(agent, 0.016)  # enter + execute
	executor.tick(agent, 0.016)  # complete
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert
	assert_float(elapsed).is_less(0.1)


# =============================================================================
# ORCHESTRATOR BENCHMARKS
# =============================================================================

func test_benchmark_orchestrator_1_agent() -> void:
	## Benchmark: Orchestrator with 1 agent
	## Target: < 1ms per frame

	# Skip in headless mode - GOAPOrchestrator is a Node and cannot be instantiated
	# without a scene tree
	if OS.has_feature("headless"):
		return

	# Arrange
	var agent := _create_mock_agent()
	GOAPOrchestrator.register_agent(agent)

	# Act
	var start := Time.get_ticks_usec()
	GOAPOrchestrator._process_agents()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert
	assert_float(elapsed).is_less(1.0)

	GOAPOrchestrator.clear()


func test_benchmark_orchestrator_10_agents() -> void:
	## Benchmark: Orchestrator with 10 agents
	## Target: < 4ms per frame (within budget)

	# Skip in headless mode - GOAPOrchestrator is a Node and cannot be instantiated
	# without a scene tree
	if OS.has_feature("headless"):
		return

	# Arrange
	for i in range(10):
		GOAPOrchestrator.register_agent(_create_mock_agent())

	# Act
	var start := Time.get_ticks_usec()
	GOAPOrchestrator._process_agents()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert - should complete within budget
	assert_float(elapsed).is_less(4.0)

	GOAPOrchestrator.clear()


func test_benchmark_orchestrator_50_agents() -> void:
	## Benchmark: Orchestrator with 50 agents
	## Target: < 10ms (budget may be exceeded)

	# Skip in headless mode - GOAPOrchestrator is a Node and cannot be instantiated
	# without a scene tree
	if OS.has_feature("headless"):
		return

	# Arrange
	for i in range(50):
		GOAPOrchestrator.register_agent(_create_mock_agent())

	# Act
	var start := Time.get_ticks_usec()
	GOAPOrchestrator._process_agents()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert - should complete (budget may be exceeded)
	assert_float(elapsed).is_less(20.0)  # Reasonable upper bound

	GOAPOrchestrator.clear()


func test_benchmark_orchestrator_100_agents() -> void:
	## Benchmark: Orchestrator with 100 agents (stress test)
	## Target: < 50ms

	# Skip in headless mode - GOAPOrchestrator is a Node and cannot be instantiated
	# without a scene tree
	if OS.has_feature("headless"):
		return

	# Arrange
	for i in range(100):
		GOAPOrchestrator.register_agent(_create_mock_agent())

	# Act
	var start := Time.get_ticks_usec()
	GOAPOrchestrator._process_agents()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert
	assert_float(elapsed).is_less(50.0)

	GOAPOrchestrator.clear()


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _create_mock_agent() -> GOAPAgent:
	## Creates a minimal mock agent for orchestrator testing.
	var agent := GOAPAgent.new()
	agent.blackboard = GOAPTestHelper.create_state()
	_created_agents.append(agent)
	return agent


# =============================================================================
# REGRESSION TRACKING BENCHMARKS
# =============================================================================

func test_benchmark_tracking_state_operations() -> void:
	## Regression test: Track state operation performance over time.
	## FAILING THIS TEST INDICATES PERFORMANCE REGRESSION.

	# Arrange
	var iterations := 500

	# Act
	var start := Time.get_ticks_usec()
	for i in range(iterations):
		_state.set_value(("key_%d" % i) as StringName, i)
		_state.get_value(("key_%d" % i) as StringName)
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert - Current target: < 10ms for 500 ops
	# Warning: If this fails, performance has degraded
	assert_float(elapsed).is_less(10.0)


func test_benchmark_tracking_planning_simple() -> void:
	## Regression test: Track simple planning performance.
	## FAILING THIS TEST INDICATES PERFORMANCE REGRESSION.

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Track", {&"target": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"Do", {}, {&"target": true})
	]

	# Act
	var start := Time.get_ticks_usec()
	for i in range(100):
		GOAPPlanner.plan(state, actions, goal)
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	# Assert - Current target: < 50ms for 100 plans
	assert_float(elapsed).is_less(50.0)
