## Unit tests for GOAPAgent.
##
## Tests the main agent controller including:[br]
## - Goal selection[br]
## - State machine transitions[br]
## - Planning integration[br]
## - Signal emissions[br]
## - Abort functionality[br][br]
##
## [b]Note:[/b] Some tests require scene tree for full integration.
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

## Test agent that bypasses scene tree requirements.
class TestAgent:
	extends GOAPAgent

	func _init() -> void:
		blackboard = GOAPState.new()
		# Don't call super._init() to avoid scene tree issues


var _agent: TestAgent


func before_test() -> void:
	_agent = TestAgent.new()


func after_test() -> void:
	_agent = null


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _create_goal(
	goal_name: StringName,
	desired_state: Dictionary[StringName, Variant],
	priority: float = 1.0
) -> GOAPGoal:
	var goal := GOAPGoal.new()
	goal.goal_name = goal_name
	goal.desired_state = desired_state
	goal.priority = priority
	return goal


func _create_action(
	goal_name: StringName,
	preconditions: Dictionary[StringName, Variant] = {},
	effects: Dictionary[StringName, Variant] = {}
) -> GOAPAction:
	var action := GOAPAction.new()
	action.action_name = goal_name
	action.preconditions = preconditions
	action.effects = effects
	return action


# =============================================================================
# INITIALIZATION TESTS
# =============================================================================

func test_new_agent_starts_idle() -> void:
	# Assert
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


func test_new_agent_has_no_current_goal() -> void:
	# Assert
	assert_that(_agent.current_goal).is_null()


func test_new_agent_has_empty_blackboard() -> void:
	# Assert
	assert_dict(_agent.blackboard.to_dict()).is_empty()


func test_new_agent_not_performing() -> void:
	# Assert
	assert_bool(_agent.is_performing()).is_false()


func test_new_agent_no_current_action() -> void:
	# Assert
	assert_that(_agent.get_current_action()).is_null()


func test_init_with_blackboard() -> void:
	# Arrange & Act
	var initial_state := GOAPState.new({&"health": 100})
	var agent := GOAPAgent.new(initial_state)

	# Assert
	assert_int(agent.blackboard.get_value(&"health")).is_equal(100)


func test_init_with_actions() -> void:
	# Arrange & Act
	var actions: Array[GOAPAction] = [_create_action(&"Test")]
	var agent := GOAPAgent.new(null, actions)

	# Assert
	assert_int(agent.actions.size()).is_equal(1)


func test_init_with_goals() -> void:
	# Arrange & Act
	var goals: Array[GOAPGoal] = [_create_goal(&"Test", {})]
	var agent := GOAPAgent.new(null, [], goals)

	# Assert
	assert_int(agent.goals.size()).is_equal(1)


# =============================================================================
# NEEDS_THINKING TESTS
# =============================================================================

func test_needs_thinking_true_when_idle() -> void:
	# Arrange
	_agent._state = GOAPAgent.State.IDLE

	# Assert
	assert_bool(_agent.needs_thinking()).is_true()


func test_needs_thinking_false_when_performing() -> void:
	# Arrange
	_agent._state = GOAPAgent.State.PERFORMING

	# Assert
	assert_bool(_agent.needs_thinking()).is_false()


# =============================================================================
# GOAL SELECTION TESTS
# =============================================================================

func test_select_goal_chooses_highest_priority() -> void:
	# Arrange
	_agent.goals = [
		_create_goal(&"LowPrio", {&"a": true}, 1.0),
		_create_goal(&"HighPrio", {&"b": true}, 10.0),
		_create_goal(&"MedPrio", {&"c": true}, 5.0)
	]

	# Act
	var selected := _agent._select_goal()

	# Assert
	assert_str(selected.goal_name).is_equal(&"HighPrio")


func test_select_goal_skips_irrelevant() -> void:
	# Arrange
	var relevant := MockGoal.create_simple(&"Relevant", {&"a": true}, 1.0)
	var irrelevant := MockGoal.create_simple(&"Irrelevant", {&"b": true}, 10.0)
	irrelevant.force_relevant = false

	_agent.goals = [irrelevant, relevant]

	# Act
	var selected := _agent._select_goal()

	# Assert
	assert_str(selected.goal_name).is_equal(&"Relevant")


func test_select_goal_skips_already_achieved() -> void:
	# Arrange
	_agent.blackboard.set_value(&"already_done", true)
	var achieved := _create_goal(&"Achieved", {&"already_done": true}, 10.0)
	var pending := _create_goal(&"Pending", {&"not_done": true}, 1.0)

	_agent.goals = [achieved, pending]

	# Act
	var selected := _agent._select_goal()

	# Assert
	assert_str(selected.goal_name).is_equal(&"Pending")


func test_select_goal_returns_null_when_none_available() -> void:
	# Arrange
	_agent.goals = []

	# Act
	var selected := _agent._select_goal()

	# Assert
	assert_that(selected).is_null()


func test_select_goal_returns_null_when_all_achieved() -> void:
	# Arrange
	_agent.blackboard.set_value(&"done", true)
	_agent.goals = [_create_goal(&"Only", {&"done": true})]

	# Act
	var selected := _agent._select_goal()

	# Assert
	assert_that(selected).is_null()


func test_select_goal_uses_dynamic_priority() -> void:
	# Arrange
	var static_goal := MockGoal.create_simple(&"Static", {&"a": true}, 5.0)
	var dynamic_goal := MockGoal.create_dynamic_priority(
		&"Dynamic",
		{&"b": true},
		func(_state) -> float: return 10.0
	)

	_agent.goals = [static_goal, dynamic_goal]

	# Act
	var selected := _agent._select_goal()

	# Assert
	assert_str(selected.goal_name).is_equal(&"Dynamic")


# =============================================================================
# STATE MACHINE TESTS
# =============================================================================

func test_think_transitions_idle_to_planning() -> void:
	# Arrange
	_agent._state = GOAPAgent.State.IDLE
	_agent.goals = [_create_goal(&"Goal", {&"target": true})]
	_agent.actions = [_create_action(&"Act", {}, {&"target": true})]

	# Act
	_agent._process_idle()

	# Assert
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.PLANNING)


func test_think_stays_idle_when_no_goal() -> void:
	# Arrange
	_agent._state = GOAPAgent.State.IDLE
	_agent.goals = []

	# Act
	_agent._process_idle()

	# Assert
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


# =============================================================================
# SIGNAL TESTS
# =============================================================================

func test_goal_selected_signal_emitted() -> void:
	# Arrange
	var goal := _create_goal(&"TestGoal", {&"a": true})
	_agent.goals = [goal]
	_agent.actions = [_create_action(&"Act", {}, {&"a": true})]

	var received_goal := [null]
	_agent.goal_selected.connect(func(g): received_goal[0] = g)

	# Act
	_agent._process_idle()

	# Assert
	assert_that(received_goal[0]).is_same(goal)


func test_plan_created_signal_emitted() -> void:
	# Arrange
	var goal := _create_goal(&"Goal", {&"done": true})
	var action := _create_action(&"Act", {}, {&"done": true})
	_agent.goals = [goal]
	_agent.actions = [action]
	_agent._state = GOAPAgent.State.IDLE

	var received_goal := [null]
	var received_plan := [[]]
	_agent.plan_created.connect(func(g, p):
		received_goal[0] = g
		received_plan[0] = p
	)

	# Act
	_agent.think()  # IDLE -> PLANNING -> PERFORMING

	# Assert
	assert_that(received_goal[0]).is_same(goal)
	assert_int(received_plan[0].size()).is_equal(1)


func test_plan_failed_signal_emitted_when_no_plan() -> void:
	# Arrange
	var goal := _create_goal(&"Impossible", {&"impossible": true})
	_agent.goals = [goal]
	_agent.actions = []  # No actions = no plan
	_agent._state = GOAPAgent.State.IDLE

	var failed_goal := [null]
	_agent.plan_failed.connect(func(g): failed_goal[0] = g)

	# Act
	_agent.think()  # IDLE -> PLANNING -> fails -> IDLE

	# Assert
	assert_that(failed_goal).is_same(goal)


# =============================================================================
# ABORT TESTS
# =============================================================================

func test_abort_returns_to_idle() -> void:
	# Arrange
	_agent._state = GOAPAgent.State.PERFORMING
	_agent.current_goal = _create_goal(&"Test", {})

	# Act
	_agent.abort()

	# Assert
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


func test_abort_clears_current_goal() -> void:
	# Arrange
	_agent._state = GOAPAgent.State.PERFORMING
	_agent.current_goal = _create_goal(&"Test", {})

	# Act
	_agent.abort()

	# Assert
	assert_that(_agent.current_goal).is_null()


func test_abort_emits_plan_aborted_signal() -> void:
	# Arrange
	var goal := _create_goal(&"AbortedGoal", {})
	_agent._state = GOAPAgent.State.PERFORMING
	_agent.current_goal = goal

	var aborted_goal := [null]
	_agent.plan_aborted.connect(func(g, _a): aborted_goal[0] = g)

	# Act
	_agent.abort()

	# Assert
	assert_that(aborted_goal[0]).is_same(goal)


func test_abort_safe_when_idle() -> void:
	# Arrange
	_agent._state = GOAPAgent.State.IDLE
	_agent.current_goal = null

	# Act & Assert - should not throw
	_agent.abort()
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


# =============================================================================
# BLACKBOARD TESTS
# =============================================================================

func test_blackboard_modifications_persist() -> void:
	# Arrange & Act
	_agent.blackboard.set_value(&"key", "value")

	# Assert
	assert_str(_agent.blackboard.get_value(&"key")).is_equal("value")


func test_blackboard_is_separate_per_agent() -> void:
	# Arrange
	var agent1 := GOAPAgent.new()
	var agent2 := GOAPAgent.new()

	# Act
	agent1.blackboard.set_value(&"key", "agent1")
	agent2.blackboard.set_value(&"key", "agent2")

	# Assert
	assert_str(agent1.blackboard.get_value(&"key")).is_equal("agent1")
	assert_str(agent2.blackboard.get_value(&"key")).is_equal("agent2")


# =============================================================================
# GET_THINK_PRIORITY TESTS
# =============================================================================

func test_get_think_priority_default_is_one() -> void:
	# Assert
	assert_float(_agent.get_think_priority()).is_equal(1.0)


# =============================================================================
# EDGE CASES
# =============================================================================

func test_multiple_goals_same_priority() -> void:
	# Arrange
	_agent.goals = [
		_create_goal(&"Goal1", {&"a": true}, 5.0),
		_create_goal(&"Goal2", {&"b": true}, 5.0),
		_create_goal(&"Goal3", {&"c": true}, 5.0)
	]

	# Act
	var selected := _agent._select_goal()

	# Assert - should select one (first found with equal priority)
	assert_that(selected).is_not_null()


func test_goal_with_empty_desired_state_always_achieved() -> void:
	# Arrange
	var empty_goal := _create_goal(&"Empty", {}, 10.0)
	var real_goal := _create_goal(&"Real", {&"target": true}, 1.0)
	_agent.goals = [empty_goal, real_goal]

	# Act
	var selected := _agent._select_goal()

	# Assert - empty goal is always achieved, so skip to real
	assert_str(selected.goal_name).is_equal(&"Real")
