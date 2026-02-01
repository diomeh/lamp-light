## Unit tests for GOAPOrchestrator.
##
## Tests the agent scheduling system including:[br]
## - Agent registration/unregistration[br]
## - Round-robin scheduling[br]
## - Frame budget enforcement[br]
## - Minimum think interval[br][br]
##
## [b]Note:[/b] These tests use mock agents that don't require scene tree.
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

## Mock agent for orchestrator testing.
## Tracks think() calls without scene tree dependency.
class MockAgent:
	extends GOAPAgent

	var think_count: int = 0
	var _needs_thinking: bool = true
	var _think_priority: float = 1.0

	func _init() -> void:
		blackboard = GOAPState.new()

	func needs_thinking() -> bool:
		return _needs_thinking

	func think() -> void:
		think_count += 1

	func get_think_priority() -> float:
		return _think_priority

	func reset() -> void:
		think_count = 0


var _orchestrator: Node
var _created_agents: Array[GOAPAgent] = []


## Creates a MockAgent and tracks it for cleanup.
func _create_mock_agent() -> MockAgent:
	var agent := auto_free(
		MockAgent.new()
	) as MockAgent
	_created_agents.append(agent)
	return agent


func before_test() -> void:
	# Get the autoload or create a new instance for testing
	_orchestrator = auto_free(Node.new()) as Node
	_orchestrator.set_script(load("res://systems/goap/core/goap_orchestrator.gd"))
	_orchestrator.clear()
	_created_agents.clear()


func after_test() -> void:
	_created_agents.clear()
	_orchestrator.clear()
	_orchestrator = null


# =============================================================================
# REGISTRATION TESTS
# =============================================================================

func test_register_agent_adds_to_list() -> void:
	# Arrange
	var agent := _create_mock_agent()

	# Act
	_orchestrator.register_agent(agent)

	# Assert
	assert_int(_orchestrator.get_agent_count()).is_equal(1)
	collect_orphan_node_details()


func test_register_multiple_agents() -> void:
	# Arrange
	var agent1 := _create_mock_agent()
	var agent2 := _create_mock_agent()
	var agent3 := _create_mock_agent()

	# Act
	_orchestrator.register_agent(agent1)
	_orchestrator.register_agent(agent2)
	_orchestrator.register_agent(agent3)

	# Assert
	assert_int(_orchestrator.get_agent_count()).is_equal(3)
	collect_orphan_node_details()


func test_register_same_agent_twice_ignored() -> void:
	# Arrange
	var agent := _create_mock_agent()

	# Act
	_orchestrator.register_agent(agent)
	_orchestrator.register_agent(agent)  # Duplicate

	# Assert
	assert_int(_orchestrator.get_agent_count()).is_equal(1)
	collect_orphan_node_details()


func test_unregister_agent_removes_from_list() -> void:
	# Arrange
	var agent := _create_mock_agent()
	_orchestrator.register_agent(agent)

	# Act
	_orchestrator.unregister_agent(agent)

	# Assert
	assert_int(_orchestrator.get_agent_count()).is_equal(0)
	collect_orphan_node_details()


func test_unregister_nonexistent_agent_no_error() -> void:
	# Arrange
	var agent := _create_mock_agent()

	# Act & Assert - should not throw
	_orchestrator.unregister_agent(agent)
	assert_int(_orchestrator.get_agent_count()).is_equal(0)
	collect_orphan_node_details()


func test_get_agents_returns_copy() -> void:
	# Arrange
	var agent := _create_mock_agent()
	_orchestrator.register_agent(agent)

	# Act
	var agents: Array[GOAPAgent] = _orchestrator.get_agents()
	agents.clear()  # Modify returned array

	# Assert - original unchanged
	assert_int(_orchestrator.get_agent_count()).is_equal(1)
	collect_orphan_node_details()


# =============================================================================
# CLEAR TESTS
# =============================================================================

func test_clear_removes_all_agents() -> void:
	# Arrange
	for i in range(5):
		_orchestrator.register_agent(_create_mock_agent())

	# Act
	_orchestrator.clear()

	# Assert
	assert_int(_orchestrator.get_agent_count()).is_equal(0)
	collect_orphan_node_details()


# =============================================================================
# IMMEDIATE FIRST THINK TESTS
# =============================================================================

func test_newly_registered_agent_can_think_immediately() -> void:
	# Arrange
	var agent := _create_mock_agent()
	agent._needs_thinking = true
	_orchestrator.register_agent(agent)

	# Act - process immediately
	_orchestrator._process_agents()

	# Assert
	assert_int(agent.think_count).is_equal(1)
	collect_orphan_node_details()


# =============================================================================
# NEEDS_THINKING FILTER TESTS
# =============================================================================

func test_agent_not_needing_think_is_skipped() -> void:
	# Arrange
	var agent := _create_mock_agent()
	agent._needs_thinking = false
	_orchestrator.register_agent(agent)

	# Act
	_orchestrator._process_agents()

	# Assert
	assert_int(agent.think_count).is_equal(0)
	collect_orphan_node_details()


func test_mixed_agents_only_thinking_ones_processed() -> void:
	# Arrange
	var thinking_agent := _create_mock_agent()
	thinking_agent._needs_thinking = true
	var idle_agent := _create_mock_agent()
	idle_agent._needs_thinking = false

	_orchestrator.register_agent(thinking_agent)
	_orchestrator.register_agent(idle_agent)

	# Act
	_orchestrator._process_agents()
	_orchestrator._process_agents()  # Second pass

	# Assert
	assert_int(thinking_agent.think_count).is_greater(0)
	assert_int(idle_agent.think_count).is_equal(0)
	collect_orphan_node_details()


# =============================================================================
# ROUND-ROBIN TESTS
# =============================================================================

func test_round_robin_cycles_through_agents() -> void:
	# Arrange - set high budget to process all
	_orchestrator.think_budget_ms = 1000.0
	_orchestrator.min_think_interval = 0.0

	var agents: Array[MockAgent] = []
	for i in range(3):
		var agent := _create_mock_agent()
		agent._needs_thinking = true
		agents.append(agent)
		_orchestrator.register_agent(agent)

	# Act - enough passes to hit all agents
	for i in range(10):
		_orchestrator._process_agents()

	# Assert - all agents should have been processed
	for agent in agents:
		assert_int(agent.think_count).is_greater(0)
	collect_orphan_node_details()


# =============================================================================
# MIN THINK INTERVAL TESTS
# =============================================================================

func test_min_think_interval_prevents_rapid_thinking() -> void:
	# Arrange
	_orchestrator.think_budget_ms = 1000.0
	_orchestrator.min_think_interval = 10.0  # 10 seconds - won't be reached

	var agent := _create_mock_agent()
	agent._needs_thinking = true
	_orchestrator.register_agent(agent)

	# Act - first think (allowed because of -min_think_interval initialization)
	_orchestrator._process_agents()
	var first_count := agent.think_count

	# Immediately try again (should be blocked by interval)
	_orchestrator._process_agents()

	# Assert - second think should be blocked
	assert_int(agent.think_count).is_equal(first_count)
	collect_orphan_node_details()


# =============================================================================
# BUDGET TESTS
# =============================================================================

func test_budget_limits_agents_per_frame() -> void:
	# Arrange - very small budget
	_orchestrator.think_budget_ms = 0.001  # Tiny budget
	_orchestrator.min_think_interval = 0.0

	# Add many agents
	var agents: Array[MockAgent] = []
	for i in range(100):
		var agent := _create_mock_agent()
		agent._needs_thinking = true
		agents.append(agent)
		_orchestrator.register_agent(agent)

	# Act
	_orchestrator._process_agents()

	# Assert - not all agents processed in one frame
	var total_thinks := 0
	for agent in agents:
		total_thinks += agent.think_count

	# With tiny budget, shouldn't process all 100
	assert_int(total_thinks).is_less(100)
	collect_orphan_node_details()


# =============================================================================
# EMPTY STATE TESTS
# =============================================================================

func test_process_with_no_agents_does_not_crash() -> void:
	# Arrange - empty orchestrator

	# Act & Assert - should not throw
	_orchestrator._process_agents()
	assert_int(_orchestrator.get_agent_count()).is_equal(0)


# =============================================================================
# CONFIGURATION TESTS
# =============================================================================

func test_default_think_budget() -> void:
	# Assert
	assert_float(_orchestrator.think_budget_ms).is_equal(4.0)


func test_default_min_think_interval() -> void:
	# Assert
	assert_float(_orchestrator.min_think_interval).is_equal(0.3)


func test_budget_can_be_modified() -> void:
	# Act
	_orchestrator.think_budget_ms = 10.0

	# Assert
	assert_float(_orchestrator.think_budget_ms).is_equal(10.0)


func test_interval_can_be_modified() -> void:
	# Act
	_orchestrator.min_think_interval = 1.0

	# Assert
	assert_float(_orchestrator.min_think_interval).is_equal(1.0)


# =============================================================================
# STRESS TESTS
# =============================================================================

func test_handles_many_agents() -> void:
	# Arrange
	_orchestrator.think_budget_ms = 100.0
	_orchestrator.min_think_interval = 0.0

	for i in range(100):
		var agent := _create_mock_agent()
		agent._needs_thinking = true
		_orchestrator.register_agent(agent)

	# Act
	var start := Time.get_ticks_usec()
	_orchestrator._process_agents()
	var elapsed := Time.get_ticks_usec() - start

	# Assert - should complete within budget (+ overhead)
	assert_int(_orchestrator.get_agent_count()).is_equal(100)
	# Allow some overhead beyond stated budget
	assert_bool(elapsed < 200000).is_true()  # 200ms max
	collect_orphan_node_details()


func test_dynamic_agent_add_remove() -> void:
	# Arrange
	_orchestrator.think_budget_ms = 100.0
	_orchestrator.min_think_interval = 0.0

	var persistent_agent := _create_mock_agent()
	persistent_agent._needs_thinking = true
	_orchestrator.register_agent(persistent_agent)

	# Act - add and remove agents dynamically
	for i in range(10):
		var temp_agent := _create_mock_agent()
		_orchestrator.register_agent(temp_agent)
		_orchestrator._process_agents()
		_orchestrator.unregister_agent(temp_agent)

	# Assert - persistent agent still tracked
	assert_int(_orchestrator.get_agent_count()).is_equal(1)
	assert_int(persistent_agent.think_count).is_greater(0)
	collect_orphan_node_details()
