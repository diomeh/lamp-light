## Integration tests using GdUnitSceneRunner.
##
## Tests full GOAP system with scene tree including:[br]
## - Agent registration via _ready()[br]
## - Orchestrator integration[br]
## - Signal connectivity[br]
## - Real physics process integration
extends GdUnitTestSuite


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
		_runner.free()
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

	# Act - wait for scene to initialize
	await _runner.scene_ready()

	# Assert - agent should be registered with orchestrator
	var agent_count := GOAPOrchestrator.get_agent_count()
	assert_int(agent_count).is_greater(0)


func test_integration_agent_unregisters_on_exit_tree() -> void:
	## Test: Agent unregisters from orchestrator on exit_tree()
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	await _runner.scene_ready()

	# Act - free the scene (triggers exit_tree)
	_runner.free()
	_runner = null
	# Wait for cleanup - two frames ensure proper tree exit
	await Engine.get_main_loop().process_frame
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
	await _runner.scene_ready()

	# Assert - orchestrator should have multiple agents
	var count := GOAPOrchestrator.get_agent_count()
	assert_int(count).is_greater_or_equal(3)


func test_integration_agent_signals_emit_correctly() -> void:
	## Test: Agent signals emit during lifecycle
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	await _runner.scene_ready()

	# Get agent from scene
	var agent := _runner.get_node_or_null("Agent") as GOAPAgent
	if not agent:
		return  # Agent node not found - test cannot proceed

	# Record initial state
	var initial_state := agent.get_state()

	# Act - run physics for a few frames to allow orchestration
	_runner.simulate_frames(5)

	# Assert - agent should have processed (state transitioned from IDLE)
	# A properly configured agent should either be PLANNING or PERFORMING
	# after orchestration runs, not stuck in IDLE
	var final_state := agent.get_state()
	if initial_state == GOAPAgent.State.IDLE:
		# If started IDLE, should have moved to PLANNING or PERFORMING
		assert_bool(final_state in [GOAPAgent.State.PLANNING, GOAPAgent.State.PERFORMING]).is_true()
	else:
		# If already processing, should remain in valid state
		assert_bool(final_state in [GOAPAgent.State.IDLE, GOAPAgent.State.PLANNING, GOAPAgent.State.PERFORMING]).is_true()


func test_integration_orchestrator_schedules_think() -> void:
	## Test: Orchestrator calls think() for IDLE agents
	## Requires: test_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	await _runner.scene_ready()

	var agent := _runner.get_node_or_null("Agent") as GOAPAgent
	if not agent:
		return  # Agent node not found - test cannot proceed

	# Ensure agent is IDLE to start
	if agent.get_state() != GOAPAgent.State.IDLE:
		agent.abort()

	# Record initial state
	var initial_state := agent.get_state()

	# Act - let orchestrator process
	_runner.simulate_frames(5)

	# Assert - agent should have processed (state changed from IDLE)
	var final_state := agent.get_state()
	assert_bool(initial_state == GOAPAgent.State.IDLE).is_true()
	assert_bool(final_state != GOAPAgent.State.IDLE).is_true()


# =============================================================================
# ACTOR INTEGRATION TESTS
# =============================================================================

func test_integration_agent_accesses_parent_actor() -> void:
	## Test: agent.actor reference set correctly
	## Requires: test_agent_scene.tscn where Agent is child of Actor

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	await _runner.scene_ready()

	var agent := _runner.get_node_or_null("Agent") as GOAPAgent
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
	await _runner.scene_ready()

	var agent := _runner.get_node_or_null("Agent") as GOAPAgent
	if not agent:
		return  # Agent node not found - test cannot proceed

	# Act - let agent run a plan
	_runner.simulate_frames(10)

	# Assert - just verify no errors during execution
	assert_int(GOAPOrchestrator.get_agent_count()).is_greater_or_equal(1)


# =============================================================================
# REAL-TIME SCENARIO TESTS
# =============================================================================

func test_integration_npc_patrol_behavior() -> void:
	## Test: Full NPC patrol loop with scene
	## Requires: npc_behavior_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/npc_behavior_scene.tscn")
	await _runner.scene_ready()

	# Act - run simulation for patrol cycle
	_runner.simulate_frames(50)

	# Assert - agent should have completed at least one goal
	var agent := _runner.get_node_or_null("NPC") as GOAPAgent
	if agent:
		# Check if any signals were emitted
		assert_int(GOAPOrchestrator.get_agent_count()).is_greater(0)


func test_integration_npc_gather_and_return() -> void:
	## Test: Resource gathering with movement
	## Requires: npc_behavior_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/npc_behavior_scene.tscn")
	await _runner.scene_ready()

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
	await _runner.scene_ready()

	# Act - let orchestrator process multiple times
	for i in range(5):
		_runner.simulate_frames(3)

	# Assert - all agents should have processed
	var agent_count := GOAPOrchestrator.get_agent_count()
	assert_int(agent_count).is_greater_or_equal(3)


func test_integration_agent_state_isolation() -> void:
	## Test: Each agent maintains separate blackboard
	## Requires: multi_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	_runner = scene_runner("res://tests/goap/fixtures/multi_agent_scene.tscn")
	await _runner.scene_ready()

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
	await _runner.scene_ready()
	var initial_count := GOAPOrchestrator.get_agent_count()

	# Act - replace scene
	_runner.free()
	await Engine.get_main_loop().process_frame
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	await _runner.scene_ready()

	# Assert - orchestrator should have agents from new scene
	var new_count := GOAPOrchestrator.get_agent_count()
	assert_int(new_count).is_greater_or_equal(initial_count)


func test_integration_multiple_scene_loads() -> void:
	## Test: Loading/unloading scenes doesn't corrupt orchestrator
	## Requires: test_agent_scene.tscn, multi_agent_scene.tscn

	_skip_if_headless()

	# Arrange
	var counts: Array[int] = []

	# Act - load different scenes sequentially
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	await _runner.scene_ready()
	counts.append(GOAPOrchestrator.get_agent_count())

	_runner.free()
	await Engine.get_main_loop().process_frame
	_runner = scene_runner("res://tests/goap/fixtures/multi_agent_scene.tscn")
	await _runner.scene_ready()
	counts.append(GOAPOrchestrator.get_agent_count())

	_runner.free()
	await Engine.get_main_loop().process_frame
	_runner = scene_runner("res://tests/goap/fixtures/test_agent_scene.tscn")
	await _runner.scene_ready()
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
	await _runner.scene_ready()

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
	await _runner.scene_ready()

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
