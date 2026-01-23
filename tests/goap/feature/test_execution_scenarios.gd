## Feature tests for GOAP execution scenarios.
##
## Tests realistic action execution including:[br]
## - Multi-step plan execution[br]
## - State modification during execution[br]
## - Failure handling and recovery[br]
## - Async action patterns
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

var _executor: GOAPExecutor
var _agent: GOAPAgent


func before_test() -> void:
	_executor = GOAPExecutor.new()
	_agent = GOAPAgent.new()
	_agent.blackboard = GOAPTestHelper.create_state()


func after_test() -> void:
	_executor = null
	if _agent:
		_agent.free()
		_agent = null


# =============================================================================
# SEQUENTIAL EXECUTION TESTS
# =============================================================================

func test_execution_three_step_sequence() -> void:
	## Scenario: Execute a simple three-step plan.

	# Arrange
	var step1 := MockAction.create_succeeding(&"Step1", {}, {&"step1": true})
	var step2 := MockAction.create_succeeding(&"Step2", {&"step1": true}, {&"step2": true})
	var step3 := MockAction.create_succeeding(&"Step3", {&"step2": true}, {&"step3": true})
	var plan: Array[GOAPAction] = [step1, step2, step3]

	var data := {"completed": false}
	_executor.plan_completed.connect(func(): data.completed = true)
	_executor.start(plan)

	# Act - tick through all actions
	for i in range(10):  # More than enough
		_executor.tick(_agent, 0.016)
		if data.completed:
			break

	# Assert
	assert_bool(data.completed).is_true()
	assert_bool(step1.exit_called).is_true()
	assert_bool(step2.exit_called).is_true()
	assert_bool(step3.exit_called).is_true()


func test_execution_correct_order() -> void:
	## Scenario: Verify actions execute in correct order.

	# Arrange
	var execution_order: Array[StringName] = []

	var action1 := MockAction.new()
	action1.action_name = &"First"
	action1.on_enter = func(_a): execution_order.append(&"First")

	var action2 := MockAction.new()
	action2.action_name = &"Second"
	action2.on_enter = func(_a): execution_order.append(&"Second")

	var action3 := MockAction.new()
	action3.action_name = &"Third"
	action3.on_enter = func(_a): execution_order.append(&"Third")

	var plan: Array[GOAPAction] = [action1, action2, action3]
	_executor.start(plan)

	# Act
	for i in range(10):
		_executor.tick(_agent, 0.016)

	# Assert
	assert_array(execution_order).is_equal([&"First", &"Second", &"Third"])


# =============================================================================
# STATE MODIFICATION TESTS
# =============================================================================

func test_execution_modifies_state() -> void:
	## Scenario: Actions should modify blackboard during execution.

	# Arrange
	_agent.blackboard = GOAPTestHelper.create_state({&"resources": 0})

	var gather := MockAction.create_succeeding(&"Gather", {}, {&"resources": 10})
	gather.state_modifications = {&"resources": 10}

	var plan: Array[GOAPAction] = [gather]
	_executor.start(plan)

	# Act
	_executor.tick(_agent, 0.016)

	# Assert
	assert_int(_agent.blackboard.get_value(&"resources")).is_equal(10)


func test_execution_cumulative_state_changes() -> void:
	## Scenario: Multiple actions modify state cumulatively.

	# Arrange
	_agent.blackboard = GOAPTestHelper.create_state({&"gold": 0})

	var work1 := MockAction.new()
	work1.action_name = &"Work1"
	work1.mock_result = GOAPAction.ExecResult.SUCCESS
	work1.on_execute = func(agent): agent.blackboard.set_value(&"gold", 10)

	var work2 := MockAction.new()
	work2.action_name = &"Work2"
	work2.mock_result = GOAPAction.ExecResult.SUCCESS
	work2.on_execute = func(agent): agent.blackboard.set_value(&"gold", 25)

	var plan: Array[GOAPAction] = [work1, work2]
	_executor.start(plan)

	# Act
	_executor.tick(_agent, 0.016)  # work1
	_executor.tick(_agent, 0.016)  # work2
	_executor.tick(_agent, 0.016)  # complete

	# Assert
	assert_int(_agent.blackboard.get_value(&"gold")).is_equal(25)


# =============================================================================
# ASYNC ACTION TESTS
# =============================================================================

func test_execution_delayed_action() -> void:
	## Scenario: Action that takes multiple frames to complete.

	# Arrange
	var slow_action := MockAction.create_delayed(&"SlowAction", 5)
	var fast_action := MockAction.create_succeeding(&"FastAction")
	var plan: Array[GOAPAction] = [slow_action, fast_action]
	var current: GOAPAction

	_executor.start(plan)

	# Act - tick through slow action
	for i in range(5):
		_executor.tick(_agent, 0.016)
		current = _executor.get_current_action()
		if current != null:
			assert_str(current.action_name).is_equal(&"SlowAction")

	# One more tick to complete slow and start fast
	_executor.tick(_agent, 0.016)

	# Assert - should have moved to fast action
	current = _executor.get_current_action()
	if current != null:
		assert_str(current.action_name).is_equal(&"FastAction")


func test_execution_mixed_duration_actions() -> void:
	## Scenario: Mix of instant and delayed actions.

	# Arrange
	var instant := MockAction.create_succeeding(&"Instant")
	var delayed := MockAction.create_delayed(&"Delayed", 3)
	var instant2 := MockAction.create_succeeding(&"Instant2")
	var plan: Array[GOAPAction] = [instant, delayed, instant2]

	var data := {"completed": false}
	_executor.plan_completed.connect(func(): data.completed = true)
	_executor.start(plan)

	# Act - count required ticks
	var ticks := 0
	while not data.completed and ticks < 20:
		_executor.tick(_agent, 0.016)
		ticks += 1

	# Assert - should complete in reasonable ticks
	# instant(1) + delayed(4) + instant2(1) + completion(1) = 7
	assert_bool(data.completed).is_true()
	assert_int(ticks).is_less_equal(10)


# =============================================================================
# FAILURE HANDLING TESTS
# =============================================================================

func test_execution_early_failure_stops_plan() -> void:
	## Scenario: First action fails, subsequent actions not executed.

	# Arrange
	var failing := MockAction.create_failing(&"Failing")
	var never_reached := MockAction.new()
	never_reached.action_name = &"NeverReached"
	var plan: Array[GOAPAction] = [failing, never_reached]

	var data := {"failed": false}
	_executor.plan_failed.connect(func(_a): data.failed = true)
	_executor.start(plan)

	# Act
	_executor.tick(_agent, 0.016)

	# Assert
	assert_bool(data.failed).is_true()
	assert_bool(never_reached.enter_called).is_false()


func test_execution_mid_plan_failure() -> void:
	## Scenario: Action fails mid-plan, cleanup happens.

	# Arrange
	var success1 := MockAction.create_succeeding(&"Success1")
	var failing := MockAction.create_failing(&"Failing")
	var success2 := MockAction.create_succeeding(&"Success2")
	var plan: Array[GOAPAction] = [success1, failing, success2]

	var data := {"failed_action": null}
	_executor.plan_failed.connect(func(a): data.failed_action = a)
	_executor.start(plan)

	# Act
	_executor.tick(_agent, 0.016)  # success1
	_executor.tick(_agent, 0.016)  # failing

	# Assert
	assert_str(data.failed_action.action_name).is_equal(&"Failing")
	assert_bool(failing.exit_called).is_true()
	assert_bool(success2.enter_called).is_false()


func test_execution_failure_after_delay() -> void:
	## Scenario: Action runs for a while then fails.

	# Arrange
	var delayed_fail := MockAction.create_delayed(&"DelayedFail", 3, GOAPAction.ExecResult.FAILURE)
	var plan: Array[GOAPAction] = [delayed_fail]

	var data := {"failed": false}
	_executor.plan_failed.connect(func(_a): data.failed = true)
	_executor.start(plan)

	# Act - tick through delay
	for i in range(4):
		_executor.tick(_agent, 0.016)

	# Assert
	assert_bool(data.failed).is_true()
	assert_int(delayed_fail.execute_call_count).is_equal(4)


# =============================================================================
# LIFECYCLE TESTS
# =============================================================================

func test_execution_enter_exit_pairs() -> void:
	## Scenario: Every entered action should be exited.

	# Arrange
	var actions: Array[MockAction] = []
	for i in range(5):
		var action := MockAction.create_succeeding(("Action%d" % i) as StringName)
		actions.append(action)

	var plan: Array[GOAPAction] = []
	for a in actions:
		plan.append(a)

	_executor.start(plan)

	# Act
	for i in range(10):
		_executor.tick(_agent, 0.016)

	# Assert - all entered should be exited
	for action in actions:
		assert_bool(action.enter_called).is_true()
		assert_bool(action.exit_called).is_true()


func test_execution_abort_exits_current() -> void:
	## Scenario: Aborting mid-execution calls exit.

	# Arrange
	var long_action := MockAction.create_delayed(&"LongAction", 10)
	var plan: Array[GOAPAction] = [long_action]
	_executor.start(plan)
	_executor.tick(_agent, 0.016)  # Enter action

	# Act
	_executor.abort(_agent)

	# Assert
	assert_bool(long_action.enter_called).is_true()
	assert_bool(long_action.exit_called).is_true()


# =============================================================================
# SIGNAL TRACKING TESTS
# =============================================================================

func test_execution_signal_sequence() -> void:
	## Scenario: Verify correct signal sequence for multi-action plan.

	# Arrange
	var signal_log: Array[String] = []

	var action1 := MockAction.create_succeeding(&"A1")
	var action2 := MockAction.create_succeeding(&"A2")
	var plan: Array[GOAPAction] = [action1, action2]

	_executor.action_started.connect(func(a): signal_log.append("start:" + str(a.action_name)))
	_executor.action_ended.connect(func(a, _r): signal_log.append("end:" + str(a.action_name)))
	_executor.plan_completed.connect(func(): signal_log.append("completed"))

	_executor.start(plan)

	# Act
	for i in range(5):
		_executor.tick(_agent, 0.016)

	# Assert
	assert_array(signal_log).is_equal([
		"start:A1",
		"end:A1",
		"start:A2",
		"end:A2",
		"completed"
	])


# =============================================================================
# EDGE CASES
# =============================================================================

func test_execution_single_instant_action() -> void:
	## Scenario: Plan with single instant action.

	# Arrange
	var action := MockAction.create_succeeding(&"Single")
	var plan: Array[GOAPAction] = [action]

	var completed := {"value": false}
	_executor.plan_completed.connect(func(): completed.value = true)
	_executor.start(plan)

	# Act
	_executor.tick(_agent, 0.016)
	_executor.tick(_agent, 0.016)  # Completion check

	# Assert
	assert_bool(completed.value).is_true()


func test_execution_restart_mid_plan() -> void:
	## Scenario: Starting new plan while executing another.

	# Arrange
	var old_action := MockAction.create_delayed(&"Old", 10)
	var new_action := MockAction.create_succeeding(&"New")

	_executor.start([old_action] as Array[GOAPAction])
	_executor.tick(_agent, 0.016)  # Enter old

	# Act - start new plan (abort is called but without agent, so old action's exit is NOT called)
	_executor.start([new_action] as Array[GOAPAction])
	_executor.tick(_agent, 0.016)  # Enter new

	# Assert
	# Note: abort() without agent doesn't call exit() on current action
	assert_bool(new_action.enter_called).is_true()
	var current := _executor.get_current_action()
	if current != null:
		assert_str(current.action_name).is_equal(&"New")


func test_execution_progress_tracking() -> void:
	## Scenario: Track execution progress through plan.

	# Arrange
	var actions: Array[MockAction] = []
	for i in range(5):
		actions.append(MockAction.create_succeeding(("A%d" % i) as StringName))

	var plan: Array[GOAPAction] = []
	for a in actions:
		plan.append(a)

	_executor.start(plan)

	# Act & Assert - track index as we progress
	for expected_index in range(5):
		_executor.tick(_agent, 0.016)
		var current_index := _executor.get_current_index()
		var current_action := _executor.get_current_action()
		# After tick, if we haven't completed, index should be >= expected
		if current_action != null:
			assert_int(current_index).is_greater_or_equal(expected_index)
