## Unit tests for GOAPAction.
##
## Tests action functionality including:[br]
## - Precondition checking[br]
## - Effect application[br]
## - Cost calculation[br]
## - Condition satisfaction[br]
## - Backward regression for planning
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

var _action: GOAPAction


func before_test() -> void:
	_action = GOAPAction.new()


func after_test() -> void:
	_action = null


# =============================================================================
# INITIALIZATION TESTS
# =============================================================================

func test_default_action_has_unnamed_name() -> void:
	# Assert
	assert_str(_action.action_name).is_equal(&"Unnamed Action")


func test_default_action_has_cost_one() -> void:
	# Assert
	assert_float(_action.cost).is_equal(1.0)


func test_default_action_has_empty_preconditions() -> void:
	# Assert
	assert_dict(_action.preconditions).is_empty()


func test_default_action_has_empty_effects() -> void:
	# Assert
	assert_dict(_action.effects).is_empty()


# =============================================================================
# GET_COST TESTS
# =============================================================================

func test_get_cost_returns_static_by_default() -> void:
	# Arrange
	_action.cost = 3.5
	var state: Dictionary[StringName, Variant] = {}

	# Act
	var result := _action.get_cost(state)

	# Assert
	assert_float(result).is_equal(3.5)


# =============================================================================
# GET_PRECONDITIONS TESTS
# =============================================================================

func test_get_preconditions_returns_static_by_default() -> void:
	# Arrange
	_action.preconditions = {&"has_tool": true}
	var state: Dictionary[StringName, Variant] = {}

	# Act
	var result := _action.get_preconditions(state)

	# Assert
	assert_dict(result).is_equal(_action.preconditions)


# =============================================================================
# GET_EFFECTS TESTS
# =============================================================================

func test_get_effects_returns_static_by_default() -> void:
	# Arrange
	_action.effects = {&"task_done": true}
	var state: Dictionary[StringName, Variant] = {}

	# Act
	var result := _action.get_effects(state)

	# Assert
	assert_dict(result).is_equal(_action.effects)


# =============================================================================
# CAN_EXECUTE TESTS
# =============================================================================

func test_can_execute_empty_preconditions_always_true() -> void:
	# Arrange
	_action.preconditions = {}
	var state: Dictionary[StringName, Variant] = {&"anything": true}

	# Act & Assert
	assert_bool(_action.can_execute(state)).is_true()


func test_can_execute_all_preconditions_met_returns_true() -> void:
	# Arrange
	_action.preconditions = {
		&"has_axe": true,
		&"stamina": 50
	}
	var state: Dictionary[StringName, Variant] = {
		&"has_axe": true,
		&"stamina": 50,
		&"extra": "ignored"
	}

	# Act & Assert
	assert_bool(_action.can_execute(state)).is_true()


func test_can_execute_missing_precondition_returns_false() -> void:
	# Arrange
	_action.preconditions = {
		&"has_axe": true,
		&"has_helmet": true
	}
	var state: Dictionary[StringName, Variant] = {
		&"has_axe": true
		# has_helmet missing
	}

	# Act & Assert
	assert_bool(_action.can_execute(state)).is_false()


func test_can_execute_wrong_value_returns_false() -> void:
	# Arrange
	_action.preconditions = {&"energy": 100}
	var state: Dictionary[StringName, Variant] = {&"energy": 50}

	# Act & Assert
	assert_bool(_action.can_execute(state)).is_false()


# =============================================================================
# APPLY_EFFECTS TESTS
# =============================================================================

func test_apply_effects_creates_new_state() -> void:
	# Arrange
	var initial := GOAPTestHelper.create_state({&"original": true})
	_action.effects = {&"new_effect": true}

	# Act
	var result := _action.apply_effects(initial)

	# Assert - new state has effect
	assert_bool(result.get_value(&"new_effect")).is_true()
	# Original unchanged
	assert_bool(initial.has_value(&"new_effect")).is_false()


func test_apply_effects_overwrites_existing_values() -> void:
	# Arrange
	var initial := GOAPTestHelper.create_state({&"status": "waiting"})
	_action.effects = {&"status": "complete"}

	# Act
	var result := _action.apply_effects(initial)

	# Assert
	assert_str(result.get_value(&"status")).is_equal("complete")


func test_apply_effects_preserves_unaffected_values() -> void:
	# Arrange
	var initial := GOAPTestHelper.create_state({&"health": 100, &"mana": 50})
	_action.effects = {&"mana": 100}  # Only changes mana

	# Act
	var result := _action.apply_effects(initial)

	# Assert
	assert_int(result.get_value(&"health")).is_equal(100)  # Preserved
	assert_int(result.get_value(&"mana")).is_equal(100)  # Changed


# =============================================================================
# EXECUTE TESTS
# =============================================================================

func test_execute_returns_success_by_default() -> void:
	# Arrange - default implementation

	# Act
	var result := _action.execute(null, 0.016)

	# Assert
	assert_int(result).is_equal(GOAPAction.ExecResult.SUCCESS)


# =============================================================================
# ENTER/EXIT TESTS
# =============================================================================

func test_enter_does_not_crash() -> void:
	# Act & Assert - should not throw
	_action.enter(null)


func test_exit_does_not_crash() -> void:
	# Act & Assert - should not throw
	_action.exit(null)


# =============================================================================
# SATISFIES_ANY TESTS
# =============================================================================

func test_satisfies_any_matching_effect_returns_true() -> void:
	# Arrange
	_action.effects = {
		&"has_wood": true,
		&"tree_nearby": false
	}
	var unsatisfied: Dictionary[StringName, Variant] = {
		&"has_wood": true  # Matches effect
	}

	# Act & Assert
	assert_bool(_action.satisfies_any(unsatisfied)).is_true()


func test_satisfies_any_no_match_returns_false() -> void:
	# Arrange
	_action.effects = {&"has_wood": true}
	var unsatisfied: Dictionary[StringName, Variant] = {
		&"has_stone": true  # Different key
	}

	# Act & Assert
	assert_bool(_action.satisfies_any(unsatisfied)).is_false()


func test_satisfies_any_wrong_value_returns_false() -> void:
	# Arrange
	_action.effects = {&"count": 10}
	var unsatisfied: Dictionary[StringName, Variant] = {
		&"count": 20  # Same key, different value
	}

	# Act & Assert
	assert_bool(_action.satisfies_any(unsatisfied)).is_false()


func test_satisfies_any_partial_match_returns_true() -> void:
	# Arrange
	_action.effects = {&"effect_a": true}
	var unsatisfied: Dictionary[StringName, Variant] = {
		&"effect_a": true,  # Matches
		&"effect_b": true   # Doesn't match, but one is enough
	}

	# Act & Assert
	assert_bool(_action.satisfies_any(unsatisfied)).is_true()


func test_satisfies_any_empty_effects_returns_false() -> void:
	# Arrange
	_action.effects = {}
	var unsatisfied: Dictionary[StringName, Variant] = {&"anything": true}

	# Act & Assert
	assert_bool(_action.satisfies_any(unsatisfied)).is_false()


# =============================================================================
# REGRESS_CONDITIONS TESTS (Critical for Planning)
# =============================================================================

func test_regress_removes_satisfied_conditions() -> void:
	# Arrange
	_action.preconditions = {}
	_action.effects = {&"has_wood": true}
	var unsatisfied: Dictionary[StringName, Variant] = {
		&"has_wood": true,
		&"has_stone": true
	}

	# Act
	var result := _action.regress_conditions(unsatisfied)

	# Assert - has_wood removed (satisfied by effect)
	assert_bool(result.has(&"has_wood")).is_false()
	assert_bool(result.has(&"has_stone")).is_true()


func test_regress_adds_preconditions() -> void:
	# Arrange
	_action.preconditions = {&"has_axe": true}
	_action.effects = {&"has_wood": true}
	var unsatisfied: Dictionary[StringName, Variant] = {&"has_wood": true}

	# Act
	var result := _action.regress_conditions(unsatisfied)

	# Assert - precondition added, effect removed
	assert_bool(result.has(&"has_axe")).is_true()
	assert_bool(result.has(&"has_wood")).is_false()


func test_regress_precondition_overwrites_unsatisfied() -> void:
	# Arrange
	_action.preconditions = {&"energy": 50}  # Requires 50
	_action.effects = {&"task_done": true}
	var unsatisfied: Dictionary[StringName, Variant] = {
		&"task_done": true,
		&"energy": 100  # Different value
	}

	# Act
	var result := _action.regress_conditions(unsatisfied)

	# Assert - precondition value wins
	assert_int(result[&"energy"]).is_equal(50)


func test_regress_with_state_filters_already_satisfied() -> void:
	# Arrange
	_action.preconditions = {&"has_axe": true, &"has_helmet": true}
	_action.effects = {&"has_wood": true}
	var unsatisfied: Dictionary[StringName, Variant] = {&"has_wood": true}

	# State already has axe
	var state := GOAPTestHelper.create_state({&"has_axe": true})

	# Act
	var result := _action.regress_conditions(unsatisfied, state)

	# Assert - has_axe filtered out (already satisfied), has_helmet remains
	assert_bool(result.has(&"has_axe")).is_false()
	assert_bool(result.has(&"has_helmet")).is_true()


func test_regress_empty_unsatisfied_adds_preconditions() -> void:
	# Arrange
	_action.preconditions = {&"prereq": true}
	_action.effects = {}
	var unsatisfied: Dictionary[StringName, Variant] = {}

	# Act
	var result := _action.regress_conditions(unsatisfied)

	# Assert
	assert_bool(result.has(&"prereq")).is_true()


func test_regress_without_state_keeps_all_preconditions() -> void:
	# Arrange
	_action.preconditions = {&"a": true, &"b": true}
	_action.effects = {&"goal": true}
	var unsatisfied: Dictionary[StringName, Variant] = {&"goal": true}

	# Act - no state provided
	var result := _action.regress_conditions(unsatisfied, null)

	# Assert - all preconditions present
	assert_bool(result.has(&"a")).is_true()
	assert_bool(result.has(&"b")).is_true()


# =============================================================================
# MOCK ACTION TESTS
# =============================================================================

func test_mock_action_tracks_enter_called() -> void:
	# Arrange
	var mock_action := MockAction.new()

	# Act
	mock_action.enter(null)

	# Assert
	assert_bool(mock_action.enter_called).is_true()


func test_mock_action_tracks_execute_count() -> void:
	# Arrange
	var mock_action := MockAction.new()

	# Act
	mock_action.execute(null, 0.0)
	mock_action.execute(null, 0.0)
	mock_action.execute(null, 0.0)

	# Assert
	assert_int(mock_action.execute_call_count).is_equal(3)


func test_mock_action_tracks_exit_called() -> void:
	# Arrange
	var mock_action := MockAction.new()

	# Act
	mock_action.exit(null)

	# Assert
	assert_bool(mock_action.exit_called).is_true()


func test_mock_action_returns_configured_result() -> void:
	# Arrange
	var mock_action := MockAction.new()
	mock_action.mock_result = GOAPAction.ExecResult.FAILURE

	# Act
	var result := mock_action.execute(null, 0.0)

	# Assert
	assert_int(result).is_equal(GOAPAction.ExecResult.FAILURE)


func test_mock_action_delayed_execution() -> void:
	# Arrange
	var mock_action := MockAction.new()
	mock_action.execute_frames = 2
	mock_action.mock_result = GOAPAction.ExecResult.SUCCESS

	# Act & Assert
	assert_int(mock_action.execute(null, 0.0)).is_equal(GOAPAction.ExecResult.RUNNING)  # Frame 1
	assert_int(mock_action.execute(null, 0.0)).is_equal(GOAPAction.ExecResult.RUNNING)  # Frame 2
	assert_int(mock_action.execute(null, 0.0)).is_equal(GOAPAction.ExecResult.SUCCESS)  # Frame 3


func test_mock_action_reset_clears_tracking() -> void:
	# Arrange
	var mock_action := MockAction.new()
	mock_action.enter(null)
	mock_action.execute(null, 0.0)
	mock_action.exit(null)

	# Act
	mock_action.reset()

	# Assert
	assert_bool(mock_action.enter_called).is_false()
	assert_int(mock_action.execute_call_count).is_equal(0)
	assert_bool(mock_action.exit_called).is_false()


func test_mock_action_on_enter_callback() -> void:
	# Arrange
	var mock_action := MockAction.new()
	var callback_invoked := [false]
	mock_action.on_enter = func(_agent): callback_invoked[0] = true

	# Act
	mock_action.enter(null)

	# Assert
	assert_bool(callback_invoked[0]).is_true()


func test_mock_action_on_execute_callback() -> void:
	# Arrange
	var mock_action := MockAction.new()
	var callback_count := [0]
	mock_action.on_execute = func(_agent): callback_count[0] += 1

	# Act
	mock_action.execute(null, 0.0)
	mock_action.execute(null, 0.0)

	# Assert
	assert_int(callback_count[0]).is_equal(2)


func test_mock_action_create_succeeding_factory() -> void:
	# Arrange & Act
	var mock_action := MockAction.create_succeeding(
		&"GatherWood",
		{&"has_axe": true},
		{&"has_wood": true}
	)

	# Assert
	assert_str(mock_action.action_name).is_equal(&"GatherWood")
	assert_dict(mock_action.preconditions).is_equal({&"has_axe": true})
	assert_dict(mock_action.effects).is_equal({&"has_wood": true})
	assert_int(mock_action.mock_result).is_equal(GOAPAction.ExecResult.SUCCESS)


func test_mock_action_create_failing_factory() -> void:
	# Arrange & Act
	var mock_action := MockAction.create_failing(&"FailAction", {&"impossible": true})

	# Assert
	assert_str(mock_action.action_name).is_equal(&"FailAction")
	assert_int(mock_action.mock_result).is_equal(GOAPAction.ExecResult.FAILURE)


func test_mock_action_create_delayed_factory() -> void:
	# Arrange & Act
	var mock_action := MockAction.create_delayed(&"LongAction", 5)

	# Assert
	assert_str(mock_action.action_name).is_equal(&"LongAction")
	assert_int(mock_action.execute_frames).is_equal(5)
