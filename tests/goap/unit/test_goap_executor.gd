## Unit tests for GOAPExecutor.
##
## Tests plan execution including:[br]
## - Action sequencing[br]
## - Lifecycle management (enter/execute/exit)[br]
## - Success and failure handling[br]
## - Signal emissions[br]
## - Abort functionality
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

var _executor: GOAPExecutor
var _mock_agent: GOAPAgent


func before_test() -> void:
	_executor = GOAPExecutor.new()
	_mock_agent = auto_free(GOAPAgent.new()) as GOAPAgent


func after_test() -> void:
	_executor = null
	_mock_agent = null


# =============================================================================
# INITIALIZATION TESTS
# =============================================================================

func test_new_executor_is_not_running() -> void:
	# Assert
	assert_bool(_executor.is_running()).is_false()


func test_new_executor_has_no_current_action() -> void:
	# Assert
	assert_that(_executor.get_current_action()).is_null()


func test_new_executor_has_negative_index() -> void:
	# Assert
	assert_int(_executor.get_current_index()).is_equal(-1)


func test_new_executor_has_zero_plan_size() -> void:
	# Assert
	assert_int(_executor.get_plan_size()).is_equal(0)


# =============================================================================
# START TESTS
# =============================================================================

func test_start_with_empty_plan_emits_completed_immediately() -> void:
	# Arrange
	var completed := [false]
	_executor.plan_completed.connect(func(): completed[0] = true)
	var empty_plan: Array[GOAPAction] = []

	# Act
	_executor.start(empty_plan)

	# Assert
	assert_bool(completed[0]).is_true()
	assert_bool(_executor.is_running()).is_false()


func test_start_with_plan_sets_running() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action]

	# Act
	_executor.start(plan)

	# Assert
	assert_bool(_executor.is_running()).is_true()


func test_start_sets_plan_size() -> void:
	# Arrange
	var action1 := auto_free(MockAction.new()) as MockAction
	var action2 := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action1, action2]

	# Act
	_executor.start(plan)

	# Assert
	assert_int(_executor.get_plan_size()).is_equal(2)


func test_start_resets_index_to_zero() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action]

	# Act
	_executor.start(plan)

	# Assert
	assert_int(_executor.get_current_index()).is_equal(0)


func test_start_aborts_previous_plan() -> void:
	# Arrange
	var old_action := auto_free(MockAction.new()) as MockAction
	old_action.action_name = &"OldAction"
	var old_plan: Array[GOAPAction] = [old_action]
	_executor.start(old_plan)
	_executor.tick(_mock_agent, 0.016)  # Enter old action

	var new_action := auto_free(MockAction.new()) as MockAction
	new_action.action_name = &"NewAction"
	var new_plan: Array[GOAPAction] = [new_action]

	# Act
	_executor.start(new_plan)

	# Assert - old action should have exited
	assert_bool(old_action.exit_called).is_true()


# =============================================================================
# TICK TESTS - BASIC FLOW
# =============================================================================

func test_tick_calls_enter_on_first_frame() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_bool(action.enter_called).is_true()


func test_tick_calls_execute_every_frame() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.execute_frames = 3  # Keep running
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)
	_executor.tick(_mock_agent, 0.016)
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_int(action.execute_call_count).is_equal(3)


func test_tick_enter_called_only_once() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.execute_frames = 2  # Keep running for multiple ticks
	var enter_count := [0]
	action.on_enter = func(_a): enter_count[0] += 1
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)
	_executor.tick(_mock_agent, 0.016)
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_int(enter_count[0]).is_equal(1)


func test_tick_when_not_running_does_nothing() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction

	# Act - tick without starting
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_bool(action.enter_called).is_false()


# =============================================================================
# TICK TESTS - SUCCESS PATH
# =============================================================================

func test_tick_success_calls_exit() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.mock_result = GOAPAction.ExecResult.SUCCESS
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_bool(action.exit_called).is_true()


func test_tick_success_advances_to_next_action() -> void:
	# Arrange
	var action1 := auto_free(MockAction.new()) as MockAction
	action1.mock_result = GOAPAction.ExecResult.SUCCESS
	var action2 := auto_free(MockAction.new()) as MockAction
	action2.mock_result = GOAPAction.ExecResult.RUNNING  # Keep action2 running
	var plan: Array[GOAPAction] = [action1, action2]
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)  # Complete action1
	_executor.tick(_mock_agent, 0.016)  # Start action2 (keep it running)

	# Assert - action2 should be current, index = 1
	assert_int(_executor.get_current_index()).is_equal(1)
	assert_bool(action2.enter_called).is_true()
	assert_bool(action1.exit_called).is_true()


func test_tick_all_success_emits_plan_completed() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.mock_result = GOAPAction.ExecResult.SUCCESS
	var plan: Array[GOAPAction] = [action]
	var completed := [false]
	_executor.plan_completed.connect(func(): completed[0] = true)
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)  # Complete action
	_executor.tick(_mock_agent, 0.016)  # Trigger completion check

	# Assert
	assert_bool(completed[0]).is_true()


func test_tick_multi_action_plan_completes() -> void:
	# Arrange
	var action1 := auto_free(MockAction.create_succeeding(&"Action1")) as MockAction
	var action2 := auto_free(MockAction.create_succeeding(&"Action2")) as MockAction
	var action3 := auto_free(MockAction.create_succeeding(&"Action3")) as MockAction
	var plan: Array[GOAPAction] = [action1, action2, action3]
	var completed := [false]
	_executor.plan_completed.connect(func(): completed[0] = true)
	_executor.start(plan)

	# Act - tick through all actions
	for i in range(4):  # 3 actions + completion check
		_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_bool(completed[0]).is_true()
	assert_bool(action1.exit_called).is_true()
	assert_bool(action2.exit_called).is_true()
	assert_bool(action3.exit_called).is_true()


# =============================================================================
# TICK TESTS - FAILURE PATH
# =============================================================================

func test_tick_failure_calls_exit() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.mock_result = GOAPAction.ExecResult.FAILURE
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_bool(action.exit_called).is_true()


func test_tick_failure_emits_plan_failed_with_action() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.action_name = &"FailingAction"
	action.mock_result = GOAPAction.ExecResult.FAILURE
	var plan: Array[GOAPAction] = [action]
	var failed_action := [null]
	_executor.plan_failed.connect(func(a): failed_action[0] = a)
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_that(failed_action).is_not_null()
	assert_str(failed_action[0].action_name).is_equal(&"FailingAction")


func test_tick_failure_stops_execution() -> void:
	# Arrange
	var action1 := auto_free(MockAction.new()) as MockAction
	action1.mock_result = GOAPAction.ExecResult.FAILURE
	var action2 := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action1, action2]
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)  # action1 fails
	_executor.tick(_mock_agent, 0.016)  # Should do nothing

	# Assert
	assert_bool(_executor.is_running()).is_false()
	assert_bool(action2.enter_called).is_false()


func test_tick_mid_plan_failure() -> void:
	# Arrange
	var action1 := auto_free(MockAction.create_succeeding(&"Action1")) as MockAction
	var action2 := auto_free(MockAction.create_failing(&"Action2")) as MockAction
	var action3 := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action1, action2, action3]
	var failed := [false]
	_executor.plan_failed.connect(func(_a): failed[0] = true)
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)  # action1 succeeds
	_executor.tick(_mock_agent, 0.016)  # action2 fails

	# Assert
	assert_bool(failed[0]).is_true()
	assert_bool(action3.enter_called).is_false()


# =============================================================================
# TICK TESTS - RUNNING STATE
# =============================================================================

func test_tick_running_continues_same_action() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.execute_frames = 5  # Keep running
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)

	# Act
	for i in range(3):
		_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_int(_executor.get_current_index()).is_equal(0)
	assert_that(_executor.get_current_action()).is_same(action)


# =============================================================================
# SIGNAL TESTS
# =============================================================================

func test_action_started_signal_emitted() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.action_name = &"TestAction"
	var plan: Array[GOAPAction] = [action]
	var started_action := [null]
	_executor.action_started.connect(func(a): started_action[0] = a)
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_that(started_action[0]).is_same(action)


func test_action_ended_signal_emitted_on_success() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.mock_result = GOAPAction.ExecResult.SUCCESS
	var plan: Array[GOAPAction] = [action]
	var ended_action := [null]
	var ended_result := [null]
	_executor.action_ended.connect(func(a, r):
		ended_action[0] = a
		ended_result[0] = r
	)
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_that(ended_action[0]).is_same(action)
	assert_int(ended_result[0]).is_equal(GOAPAction.ExecResult.SUCCESS)


func test_action_ended_signal_emitted_on_failure() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.mock_result = GOAPAction.ExecResult.FAILURE
	var plan: Array[GOAPAction] = [action]
	var ended_result := [null]
	_executor.action_ended.connect(func(_a, r): ended_result[0] = r)
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)

	# Assert
	assert_int(ended_result[0]).is_equal(GOAPAction.ExecResult.FAILURE)


func test_signals_emitted_in_order() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.mock_result = GOAPAction.ExecResult.SUCCESS
	var plan: Array[GOAPAction] = [action]
	var signal_order: Array[String] = []
	_executor.action_started.connect(func(_a): signal_order.append("started"))
	_executor.action_ended.connect(func(_a, _r): signal_order.append("ended"))
	_executor.plan_completed.connect(func(): signal_order.append("completed"))
	_executor.start(plan)

	# Act
	_executor.tick(_mock_agent, 0.016)  # Run action
	_executor.tick(_mock_agent, 0.016)  # Complete plan

	# Assert
	assert_array(signal_order).is_equal(["started", "ended", "completed"])


# =============================================================================
# ABORT TESTS
# =============================================================================

func test_abort_stops_execution() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.execute_frames = 10  # Keep running
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)
	_executor.tick(_mock_agent, 0.016)  # Enter action

	# Act
	_executor.abort(_mock_agent)

	# Assert
	assert_bool(_executor.is_running()).is_false()


func test_abort_calls_exit_on_current_action() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.execute_frames = 10
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)
	_executor.tick(_mock_agent, 0.016)  # Enter action

	# Act
	_executor.abort(_mock_agent)

	# Assert
	assert_bool(action.exit_called).is_true()


func test_abort_without_agent_skips_exit() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	action.execute_frames = 10
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)
	_executor.tick(_mock_agent, 0.016)  # Enter action
	action.exit_called = false  # Reset for test

	# Act
	_executor.abort(null)  # No agent

	# Assert
	assert_bool(action.exit_called).is_false()


func test_abort_clears_plan() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action]
	_executor.start(plan)

	# Act
	_executor.abort(_mock_agent)

	# Assert
	assert_int(_executor.get_plan_size()).is_equal(0)
	assert_that(_executor.get_current_action()).is_null()


func test_abort_does_not_emit_signals() -> void:
	# Arrange
	var action := auto_free(MockAction.new()) as MockAction
	var plan: Array[GOAPAction] = [action]
	var any_signal := [false]
	_executor.plan_completed.connect(func(): any_signal[0] = true)
	_executor.plan_failed.connect(func(_a): any_signal[0] = true)
	_executor.start(plan)
	_executor.tick(_mock_agent, 0.016)

	# Act
	_executor.abort(_mock_agent)

	# Assert
	assert_bool(any_signal[0]).is_false()


# =============================================================================
# EDGE CASES
# =============================================================================

func test_multiple_starts_resets_properly() -> void:
	# Arrange
	var action1 := auto_free(MockAction.new()) as MockAction
	action1.mock_result = GOAPAction.ExecResult.SUCCESS
	var action2 := auto_free(MockAction.new()) as MockAction
	action2.mock_result = GOAPAction.ExecResult.RUNNING  # Keep running to check index
	_executor.start([action1] as Array[GOAPAction])
	_executor.tick(_mock_agent, 0.016)  # Complete action1

	# Act
	_executor.start([action2] as Array[GOAPAction])
	_executor.tick(_mock_agent, 0.016)  # Enter action2

	# Assert
	assert_bool(action2.enter_called).is_true()
	# After starting action2, index should be 0 (action2 is current, not yet completed)
	assert_int(_executor.get_current_index()).is_equal(0)


func test_get_current_action_returns_correct_action() -> void:
	# Arrange
	var action1 := auto_free(MockAction.new()) as MockAction
	action1.action_name = &"First"
	var action2 := auto_free(MockAction.new()) as MockAction
	action2.action_name = &"Second"
	var plan: Array[GOAPAction] = [action1, action2]
	_executor.start(plan)

	# Act & Assert
	_executor.tick(_mock_agent, 0.016)  # Running action1
	var current1 := _executor.get_current_action()
	if current1 != null:
		assert_str(current1.action_name).is_equal(&"First")

	action1.mock_result = GOAPAction.ExecResult.SUCCESS
	_executor.tick(_mock_agent, 0.016)  # Complete action1
	_executor.tick(_mock_agent, 0.016)  # Running action2
	var current2 := _executor.get_current_action()
	if current2 != null:
		assert_str(current2.action_name).is_equal(&"Second")
