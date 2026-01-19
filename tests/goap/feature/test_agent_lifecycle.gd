## Feature tests for GOAP agent lifecycle scenarios.
##
## Tests complete agent behavior cycles including:[br]
## - Goal selection → Planning → Execution → Completion[br]
## - Replanning on failure[br]
## - Dynamic goal changes[br]
## - State-driven behavior
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

## Test agent without scene tree dependencies.
class LifecycleTestAgent:
	extends GOAPAgent

	func _init() -> void:
		blackboard = GOAPState.new()


var _agent: LifecycleTestAgent


func before_test() -> void:
	_agent = LifecycleTestAgent.new()


func after_test() -> void:
	_agent = null


# =============================================================================
# HELPERS
# =============================================================================

func _create_goal(goal_name: StringName, desired: Dictionary[StringName, Variant], priority: float = 1.0) -> GOAPGoal:
	var goal := GOAPGoal.new()
	goal.goal_name = goal_name
	goal.desired_state = desired
	goal.priority = priority
	return goal


func _create_action(action_name: StringName, preconds: Dictionary[StringName, Variant], effects: Dictionary[StringName, Variant]) -> MockAction:
	var action := MockAction.create_succeeding(action_name, preconds, effects)
	return action


# =============================================================================
# FULL LIFECYCLE TESTS
# =============================================================================

func test_lifecycle_idle_to_performing() -> void:
	## Scenario: Agent transitions from IDLE through PLANNING to PERFORMING.

	# Arrange
	_agent.goals = [_create_goal(&"Goal", {&"done": true})]
	_agent.actions = [_create_action(&"DoIt", {}, {&"done": true})]

	# Assert initial state
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)

	# Act
	_agent.think()

	# Assert - should be PERFORMING with plan
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.PERFORMING)
	assert_that(_agent.current_goal).is_not_null()


func test_lifecycle_complete_simple_goal() -> void:
	## Scenario: Complete a simple single-action goal.

	# Arrange
	var goal := _create_goal(&"SimpleGoal", {&"target": true})
	var action := _create_action(&"Achieve", {}, {&"target": true})

	_agent.goals = [goal]
	_agent.actions = [action]

	var completed_goal := {"goal": null}
	_agent.plan_completed.connect(func(g): completed_goal["goal"] = g)

	# Act - go through full cycle
	_agent.think()  # IDLE -> PLANNING -> PERFORMING
	_agent._process_performing(0.016)  # Execute action
	_agent._process_performing(0.016)  # Complete

	# Assert
	assert_that(completed_goal["goal"]).is_same(goal)
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


func test_lifecycle_multi_step_goal() -> void:
	## Scenario: Complete a multi-step goal.

	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.goals = [_create_goal(&"MultiStep", {&"step3": true})]
	_agent.actions = [
		_create_action(&"Step1", {}, {&"step1": true}),
		_create_action(&"Step2", {&"step1": true}, {&"step2": true}),
		_create_action(&"Step3", {&"step2": true}, {&"step3": true})
	]

	var completed := {"value": false}
	_agent.plan_completed.connect(func(_g): completed["value"] = true)

	# Act
	_agent.think()

	# Execute all steps
	for i in range(10):
		if completed["value"]:
			break
		_agent._process_performing(0.016)

	# Assert
	assert_bool(completed["value"]).is_true()


# =============================================================================
# GOAL SELECTION LIFECYCLE
# =============================================================================

func test_lifecycle_selects_highest_priority() -> void:
	## Scenario: Agent selects highest priority unachieved goal.

	# Arrange
	_agent.goals = [
		_create_goal(&"Low", {&"low": true}, 1.0),
		_create_goal(&"High", {&"high": true}, 10.0),
		_create_goal(&"Med", {&"med": true}, 5.0)
	]
	_agent.actions = [
		_create_action(&"GetLow", {}, {&"low": true}),
		_create_action(&"GetHigh", {}, {&"high": true}),
		_create_action(&"GetMed", {}, {&"med": true})
	]

	var selected_goal := {"goal": null}
	_agent.goal_selected.connect(func(g): selected_goal["goal"] = g)

	# Act
	_agent.think()

	# Assert
	assert_str(selected_goal["goal"].goal_name).is_equal(&"High")


func test_lifecycle_skips_achieved_selects_next() -> void:
	## Scenario: Agent skips achieved goals and selects next priority.

	# Arrange
	_agent.blackboard.set_value(&"high", true)  # Already achieved
	_agent.goals = [
		_create_goal(&"Low", {&"low": true}, 1.0),
		_create_goal(&"High", {&"high": true}, 10.0),  # Achieved
		_create_goal(&"Med", {&"med": true}, 5.0)
	]
	_agent.actions = [
		_create_action(&"GetLow", {}, {&"low": true}),
		_create_action(&"GetMed", {}, {&"med": true})
	]

	var selected_goal := {"goal": null}
	_agent.goal_selected.connect(func(g): selected_goal["goal"] = g)

	# Act
	_agent.think()

	# Assert
	assert_str(selected_goal["goal"].goal_name).is_equal(&"Med")


# =============================================================================
# PLANNING FAILURE LIFECYCLE
# =============================================================================

func test_lifecycle_planning_failure_returns_idle() -> void:
	## Scenario: When planning fails, agent returns to IDLE.

	# Arrange
	_agent.goals = [_create_goal(&"Impossible", {&"impossible": true})]
	_agent.actions = []  # No actions = no plan

	var plan_failed := {"value": false}
	_agent.plan_failed.connect(func(_g): plan_failed["value"] = true)

	# Act
	_agent.think()

	# Assert
	assert_bool(plan_failed["value"]).is_true()
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)
	assert_that(_agent.current_goal).is_null()


# =============================================================================
# EXECUTION FAILURE LIFECYCLE
# =============================================================================

func test_lifecycle_action_failure_aborts_plan() -> void:
	## Scenario: Action failure during execution aborts plan.

	# Arrange
	var failing_action := MockAction.create_failing(&"Failing")

	_agent.goals = [_create_goal(&"Goal", {&"done": true})]
	_agent.actions = [failing_action]
	# Override effects so planner accepts it
	failing_action.effects = {&"done": true}

	var aborted := {"value": false}
	_agent.plan_aborted.connect(func(_g, _a): aborted["value"] = true)

	# Act
	_agent.think()
	_agent._process_performing(0.016)

	# Assert
	assert_bool(aborted["value"]).is_true()
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


# =============================================================================
# GOAL COMPLETION CALLBACK TESTS
# =============================================================================

func test_lifecycle_calls_after_plan_complete() -> void:
	## Scenario: Goal's after_plan_complete is called on success.

	# Arrange
	var mock_goal := MockGoal.create_simple(&"Goal", {&"done": true})
	_agent.goals = [mock_goal]
	_agent.actions = [_create_action(&"Do", {}, {&"done": true})]

	# Act
	_agent.think()
	for i in range(5):
		_agent._process_performing(0.016)

	# Assert
	assert_int(mock_goal.completion_count).is_equal(1)


# =============================================================================
# ABORT LIFECYCLE TESTS
# =============================================================================

func test_lifecycle_abort_returns_to_idle() -> void:
	## Scenario: Aborting during execution returns to IDLE.

	# Arrange
	var slow_action := MockAction.create_delayed(&"Slow", 10)
	slow_action.effects = {&"done": true}
	_agent.goals = [_create_goal(&"Goal", {&"done": true})]
	_agent.actions = [slow_action]

	_agent.think()
	_agent._process_performing(0.016)  # Start executing

	# Act
	_agent.abort()

	# Assert
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)
	assert_that(_agent.current_goal).is_null()


func test_lifecycle_abort_emits_signal() -> void:
	## Scenario: Aborting emits plan_aborted signal.

	# Arrange
	var slow_action := MockAction.create_delayed(&"Slow", 10)
	slow_action.effects = {&"done": true}
	var goal := _create_goal(&"Goal", {&"done": true})
	_agent.goals = [goal]
	_agent.actions = [slow_action]

	var aborted_goal := {"goal": null}
	_agent.plan_aborted.connect(func(g, _a): aborted_goal["goal"] = g)

	_agent.think()
	_agent._process_performing(0.016)

	# Act
	_agent.abort()

	# Assert
	assert_that(aborted_goal["goal"]).is_same(goal)


# =============================================================================
# EARLY GOAL COMPLETION TESTS
# =============================================================================

func test_lifecycle_early_completion_by_external_change() -> void:
	## Scenario: Goal achieved by external state change during execution.

	# Arrange
	var slow_action := MockAction.create_delayed(&"Slow", 10)
	slow_action.effects = {&"done": true}
	var goal := _create_goal(&"Goal", {&"done": true})
	_agent.goals = [goal]
	_agent.actions = [slow_action]

	var completed := {"value": false}
	_agent.plan_completed.connect(func(_g): completed["value"] = true)

	_agent.think()
	_agent._process_performing(0.016)  # Start

	# Act - external change achieves goal
	_agent.blackboard.set_value(&"done", true)
	_agent._process_performing(0.016)  # Should detect completion

	# Assert
	assert_bool(completed["value"]).is_true()
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


# =============================================================================
# CONSECUTIVE GOALS TESTS
# =============================================================================

func test_lifecycle_consecutive_goals() -> void:
	## Scenario: Agent completes one goal then pursues next.

	# Arrange
	_agent.goals = [
		_create_goal(&"First", {&"first": true}, 10.0),
		_create_goal(&"Second", {&"second": true}, 5.0)
	]
	_agent.actions = [
		_create_action(&"DoFirst", {}, {&"first": true}),
		_create_action(&"DoSecond", {}, {&"second": true})
	]

	var goals_completed: Array[StringName] = []
	_agent.plan_completed.connect(func(g): goals_completed.append(g.goal_name))

	# Act - complete first goal
	_agent.think()
	for i in range(5):
		_agent._process_performing(0.016)

	# Now think again for second goal
	_agent.think()
	for i in range(5):
		_agent._process_performing(0.016)

	# Assert
	assert_array(goals_completed).contains([&"First", &"Second"])


# =============================================================================
# DYNAMIC PRIORITY TESTS
# =============================================================================

func test_lifecycle_dynamic_priority_selection() -> void:
	## Scenario: Goal selection respects dynamic priority.

	# Arrange
	var base_goal := MockGoal.create_simple(&"Base", {&"base": true}, 5.0)
	var dynamic_goal := MockGoal.create_dynamic_priority(
		&"Dynamic",
		{&"dynamic": true},
		func(_state) -> float: return 20.0  # Always high priority
	)

	_agent.goals = [base_goal, dynamic_goal]
	_agent.actions = [
		_create_action(&"DoBase", {}, {&"base": true}),
		_create_action(&"DoDynamic", {}, {&"dynamic": true})
	]

	var selected := {"goal": null}
	_agent.goal_selected.connect(func(g): selected["goal"] = g)

	# Act
	_agent.think()

	# Assert
	assert_str(selected["goal"].goal_name).is_equal(&"Dynamic")


# =============================================================================
# RELEVANCE FILTER TESTS
# =============================================================================

func test_lifecycle_irrelevant_goals_skipped() -> void:
	## Scenario: Irrelevant goals are not selected.

	# Arrange
	var irrelevant := MockGoal.create_simple(&"Irrelevant", {&"x": true}, 100.0)
	irrelevant.force_relevant = false

	var relevant := MockGoal.create_simple(&"Relevant", {&"y": true}, 1.0)

	_agent.goals = [irrelevant, relevant]
	_agent.actions = [
		_create_action(&"DoX", {}, {&"x": true}),
		_create_action(&"DoY", {}, {&"y": true})
	]

	var selected := {"goal": null}
	_agent.goal_selected.connect(func(g): selected["goal"] = g)

	# Act
	_agent.think()

	# Assert - should skip high-priority irrelevant goal
	assert_str(selected["goal"].goal_name).is_equal(&"Relevant")


# =============================================================================
# STATE PERSISTENCE TESTS
# =============================================================================

func test_lifecycle_blackboard_persists_across_goals() -> void:
	## Scenario: Blackboard state persists when moving between goals.

	# Arrange
	_agent.goals = [
		_create_goal(&"First", {&"first": true}, 10.0),
		_create_goal(&"Second", {&"second": true}, 5.0)
	]
	_agent.actions = [
		_create_action(&"DoFirst", {}, {&"first": true}),
		_create_action(&"DoSecond", {}, {&"second": true})
	]

	# Act - complete first goal
	_agent.think()
	for i in range(5):
		_agent._process_performing(0.016)

	# Assert - first goal state persists
	assert_bool(_agent.blackboard.get_value(&"first")).is_true()

	# Complete second goal
	_agent.think()
	for i in range(5):
		_agent._process_performing(0.016)

	# Assert - both states persist
	assert_bool(_agent.blackboard.get_value(&"first")).is_true()
	assert_bool(_agent.blackboard.get_value(&"second")).is_true()


# =============================================================================
# NO GOALS TESTS
# =============================================================================

func test_lifecycle_no_goals_stays_idle() -> void:
	## Scenario: Agent with no goals stays IDLE.

	# Arrange
	_agent.goals = []
	_agent.actions = [_create_action(&"Unused", {}, {})]

	# Act
	_agent.think()

	# Assert
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)


func test_lifecycle_all_goals_achieved_stays_idle() -> void:
	## Scenario: Agent with all goals achieved stays IDLE.

	# Arrange
	_agent.blackboard.set_value(&"done", true)
	_agent.goals = [_create_goal(&"Only", {&"done": true})]
	_agent.actions = []

	# Act
	_agent.think()

	# Assert
	assert_int(_agent.get_state()).is_equal(GOAPAgent.State.IDLE)
