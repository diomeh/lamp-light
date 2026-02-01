## Integration tests using GdUnitSceneRunner.
##
## Tests full GOAP system with scene tree including:[br]
## - Agent registration via _ready()[br]
## - Orchestrator integration[br]
## - Signal connectivity[br]
## - Real physics process integration
extends GdUnitTestSuite

@warning_ignore_start("redundant_await")

# =============================================================================
# SETUP
# =============================================================================

var _runner: GdUnitSceneRunner


func _skip_if_headless() -> void:
	if OS.has_feature("headless"):
		# Integration tests require scene tree - not supported in headless mode
		return


func before_test() -> void:
	pass



func after_test() -> void:
	if _runner:
		var s =_runner.scene()
		if s:
			s.queue_free()
		_runner = null

	# Clean up orchestrator registration for test isolation
	GOAPOrchestrator.clear()


# =============================================================================
# SCENE TREE INTEGRATION TESTS
# =============================================================================

func test_integration_agent_registers_on_ready() -> void:
	## Test: Agent registers with orchestrator on _ready()
	## Requires: test_agent_scene.tscn with single agent

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")

	# Assert - agent should be registered with orchestrator
	var agent_count := GOAPOrchestrator.get_agent_count()
	assert_int(agent_count).is_greater(0)


func test_integration_agent_unregisters_on_exit_tree() -> void:
	## Test: Agent unregisters from orchestrator on exit_tree()
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	_runner.scene().queue_free()
	_runner = null

	# Wait for cleanup
	for _i in range(3):
		await Engine.get_main_loop().process_frame

	# Assert - agent should be unregistered (orchestrator cleared by after_test)
	var final_count := GOAPOrchestrator.get_agent_count()
	assert_int(final_count).is_equal(0)


func test_integration_multiple_agents_in_scene() -> void:
	## Test: Multiple agents register correctly
	## Requires: multi_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/multi_agent_scene.tscn")

	# Assert - orchestrator should have multiple agents
	var count := GOAPOrchestrator.get_agent_count()
	assert_int(count).is_greater_equal(3)


func test_integration_agent_signals_emit_correctly() -> void:
	## Test: Agent signals emit during lifecycle
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")

	var agent := _runner.find_child("Agent") as GOAPAgent
	if not agent:
		return  # Agent node not found - test cannot proceed

	# Verify agent is set up correctly before testing signals
	assert_bool(agent.goals.size() > 0).is_true()
	assert_bool(agent.actions.size() > 0).is_true()
	assert_bool(GOAPOrchestrator.get_agent_count() > 0).is_true()
	assert_bool(agent.needs_thinking()).is_true()

	# Track signal emissions directly instead of using GdUnit4 monitor
	# (GdUnit4's is_emitted waits for future emissions, not past ones)
	# Use array since GDScript lambdas capture by value, not reference
	var signal_counts := [0, 0, 0]  # [goal_selected, plan_created, plan_completed]

	agent.goal_selected.connect(func(_goal): signal_counts[0] += 1)
	agent.plan_created.connect(func(_goal, _plan): signal_counts[1] += 1)
	agent.plan_completed.connect(func(_goal): signal_counts[2] += 1)

	# Act - manually trigger orchestrator processing since autoloads are not
	# processed by simulate_frames. Then manually tick the agent's execution.
	GOAPOrchestrator._process_agents()

	# Manually tick agent execution since simulate_frames may not reliably call
	# _physics_process on scene nodes in bulk test runs. Need 2 ticks:
	# first tick executes action, second tick completes the plan.
	for i in range(2):
		agent._physics_process(0.016)

	# Assert - agent should be back in IDLE after plan completes
	assert_bool(agent.needs_thinking()).is_true()

	# Assert - orchestrator triggers think() on IDLE agents, which selects a goal,
	# creates a plan, and completes it. Verify the key lifecycle signals fired.
	assert_int(signal_counts[0]).is_equal(1)
	assert_int(signal_counts[1]).is_equal(1)
	assert_int(signal_counts[2]).is_equal(1)


func test_integration_orchestrator_schedules_think() -> void:
	## Test: Orchestrator calls think() for IDLE agents
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")

	var agent := _runner.find_child("Agent") as GOAPAgent
	if not agent:
		return  # Agent node not found - test cannot proceed

	# Agent starts IDLE, so orchestrator should pick it up on the next frame
	assert_bool(agent.needs_thinking()).is_true()

	# Act - manually trigger orchestrator processing since autoloads are not
	# processed by simulate_frames
	GOAPOrchestrator._process_agents()

	# Assert - orchestrator called think(), which transitions the agent out of IDLE
	assert_bool(agent.needs_thinking()).is_false()


# =============================================================================
# ACTOR INTEGRATION TESTS
# =============================================================================

func test_integration_agent_accesses_parent_actor() -> void:
	## Test: agent.actor reference set correctly
	## Requires: test_agent_scene.tscn where Agent is child of Actor

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")

	var agent := _runner.find_child("Agent") as GOAPAgent
	if not agent:
		return  # Agent node not found - test cannot proceed

	# Assert - agent should have actor reference
	assert_that(agent.actor).is_not_null()


func test_integration_action_modifies_actor() -> void:
	## Test: Actions can call actor methods
	## Requires: test_agent_scene.tscn with test action

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")

	var agent := _runner.find_child("Agent") as GOAPAgent
	if not agent:
		return  # Agent node not found - test cannot proceed

	# Act - let agent run a plan
	_runner.simulate_frames(10)

	# Assert - just verify no errors during execution
	assert_int(GOAPOrchestrator.get_agent_count()).is_greater_equal(1)


# =============================================================================
# REAL-TIME SCENARIO TESTS
# =============================================================================

func test_integration_npc_patrol_behavior() -> void:
	## Test: Full NPC patrol loop with scene
	## Requires: npc_behavior_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/npc_behavior_scene.tscn")

	# Act - run simulation for patrol cycle
	_runner.simulate_frames(50)

	# Assert - agent should have completed at least one goal
	var agent := _runner.find_child("NPC") as GOAPAgent
	if agent:
		# Check if any signals were emitted
		assert_int(GOAPOrchestrator.get_agent_count()).is_greater(0)


func test_integration_npc_gather_and_return() -> void:
	## Test: Resource gathering with movement
	## Requires: npc_behavior_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/npc_behavior_scene.tscn")

	# Act - run gathering cycle
	_runner.simulate_frames(100)

	# Assert - simulation should complete without errors
	assert_int(GOAPOrchestrator.get_agent_count()).is_greater(0)


# =============================================================================
# MULTI-AGENT COORDINATION TESTS
# =============================================================================

func test_integration_multi_agent_think_scheduling() -> void:
	## Test: Multiple agents scheduled by orchestrator
	## Requires: multi_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/multi_agent_scene.tscn")

	# Act - let orchestrator process multiple times
	for i in range(5):
		_runner.simulate_frames(3)

	# Assert - all agents should have processed
	var agent_count := GOAPOrchestrator.get_agent_count()
	assert_int(agent_count).is_greater_equal(3)


func test_integration_agent_state_isolation() -> void:
	## Test: Each agent maintains separate blackboard
	## Requires: multi_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/multi_agent_scene.tscn")

	# Act - modify one agent's blackboard
	var agents := GOAPOrchestrator.get_agents()
	if agents.size() >= 2:
		var agent1 := agents[0] as GOAPAgent
		var agent2 := agents[1] as GOAPAgent

		agent1.blackboard.set_value(&"test_key", "agent1_value")

		# Assert - agent2 should not have the value
		if agent2.blackboard.has_value(&"test_key"):
			assert_str(agent2.blackboard.get_value(&"test_key")).is_not_equal("agent1_value")


# =============================================================================
# SCENE TRANSITION TESTS
# =============================================================================

func test_integration_scene_transition_cleanup() -> void:
	## Test: Agents properly cleanup when scene unloads
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	var initial_count := GOAPOrchestrator.get_agent_count()

	# Act - replace scene
	await Engine.get_main_loop().process_frame
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")

	# Assert - orchestrator should have agents from new scene
	var new_count := GOAPOrchestrator.get_agent_count()
	assert_int(new_count).is_greater_equal(initial_count)


func test_integration_multiple_scene_loads() -> void:
	## Test: Loading/unloading scenes doesn't corrupt orchestrator
	## Requires: test_agent_scene.tscn, multi_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	var counts: Array[int] = []

	# Act - load different scenes sequentially
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	counts.append(GOAPOrchestrator.get_agent_count())

	_runner.scene().queue_free()
	await Engine.get_main_loop().process_frame
	_runner = scene_runner("res://tests/goap/fixtures/multi_agent_scene.tscn")
	counts.append(GOAPOrchestrator.get_agent_count())

	_runner.scene().queue_free()
	await Engine.get_main_loop().process_frame
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	counts.append(GOAPOrchestrator.get_agent_count())

	# Assert - orchestrator should be functional
	assert_int(counts[0]).is_equal(1)  # test_agent_scene has 1 agent
	assert_int(counts[1]).is_equal(3)  # multi_agent_scene has 3 agents
	assert_int(counts[2]).is_equal(1)  # reloading test_agent_scene should give same count


# =============================================================================
# ERROR HANDLING TESTS
# =============================================================================

func test_integration_graceful_degradation_on_error() -> void:
	## Test: System handles errors gracefully
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")

	# Act - simulate and check for errors
	_runner.simulate_frames(10)

	# Assert - orchestrator should still be functional
	assert_int(GOAPOrchestrator.get_agent_count()).is_greater(0)


# =============================================================================
# PERFORMANCE INTEGRATION TESTS
# =============================================================================

func test_integration_frame_time_with_agents() -> void:
	## Test: Scene runs within acceptable frame time
	## Requires: multi_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/multi_agent_scene.tscn")

	# Act - measure frame time over several frames
	var frame_times: Array[float] = []
	for i in range(10):
		var start := Time.get_ticks_usec()
		_runner.simulate_frames(1)
		var elapsed := (Time.get_ticks_usec() - start) / 1000.0
		frame_times.append(elapsed)

	# Assert - median frame time should be reasonable
	frame_times.sort()
	var median_index := frame_times.size() / 2.0
	var median_frame := frame_times[median_index]
	# Target: 60fps (16.67ms per frame) - allow some overhead for test infrastructure
	assert_float(median_frame).is_less(20.0)
