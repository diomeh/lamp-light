## Unit tests for GOAPGoal.
##
## Tests goal functionality including:[br]
## - Achievement checking[br]
## - Priority calculation (static and dynamic)[br]
## - Relevance filtering[br]
## - Desired state retrieval
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

var _goal: GOAPGoal


func before_test() -> void:
	_goal = GOAPGoal.new()


func after_test() -> void:
	_goal = null


# =============================================================================
# INITIALIZATION TESTS
# =============================================================================

func test_default_goal_has_unnamed_name() -> void:
	# Assert
	assert_str(_goal.goal_name).is_equal(&"Unnamed Goal")


func test_default_goal_has_priority_one() -> void:
	# Assert
	assert_float(_goal.priority).is_equal(1.0)


func test_default_goal_has_empty_desired_state() -> void:
	# Assert
	assert_dict(_goal.desired_state).is_empty()


# =============================================================================
# IS_ACHIEVED TESTS
# =============================================================================

func test_is_achieved_empty_desired_state_always_true() -> void:
	# Arrange
	_goal.desired_state = {}
	var state: Dictionary[StringName, Variant] = {&"anything": true}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_true()


func test_is_achieved_all_conditions_met_returns_true() -> void:
	# Arrange
	_goal.desired_state = {
		&"has_food": true,
		&"hunger": 0
	}
	var state: Dictionary[StringName, Variant] = {
		&"has_food": true,
		&"hunger": 0,
		&"extra_key": "ignored"
	}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_true()


func test_is_achieved_missing_key_returns_false() -> void:
	# Arrange
	_goal.desired_state = {
		&"has_food": true,
		&"has_water": true
	}
	var state: Dictionary[StringName, Variant] = {
		&"has_food": true
		# has_water missing
	}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_false()


func test_is_achieved_wrong_value_returns_false() -> void:
	# Arrange
	_goal.desired_state = {&"health": 100}
	var state: Dictionary[StringName, Variant] = {&"health": 50}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_false()


func test_is_achieved_type_matters() -> void:
	# Arrange
	_goal.desired_state = {&"count": 5}  # int
	var state: Dictionary[StringName, Variant] = {&"count": 5.0}  # float

	# Act & Assert
	# Godot may coerce these, but explicit type check is safer
	# This test documents expected behavior
	assert_bool(_goal.is_achieved(state)).is_true()


func test_is_achieved_boolean_false_condition() -> void:
	# Arrange
	_goal.desired_state = {&"is_hungry": false}
	var state: Dictionary[StringName, Variant] = {&"is_hungry": false}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_true()


# =============================================================================
# GET_DESIRED_STATE TESTS
# =============================================================================

func test_get_desired_state_returns_static_by_default() -> void:
	# Arrange
	_goal.desired_state = {&"target": Vector3(1, 2, 3)}
	var state: Dictionary[StringName, Variant] = {}

	# Act
	var result := _goal.get_desired_state(state)

	# Assert
	assert_dict(result).is_equal(_goal.desired_state)


# =============================================================================
# IS_RELEVANT TESTS
# =============================================================================

func test_is_relevant_returns_true_by_default() -> void:
	# Arrange
	var state: Dictionary[StringName, Variant] = {}

	# Act & Assert
	assert_bool(_goal.is_relevant(state)).is_true()


# =============================================================================
# GET_PRIORITY TESTS
# =============================================================================

func test_get_priority_returns_static_by_default() -> void:
	# Arrange
	_goal.priority = 5.5
	var state: Dictionary[StringName, Variant] = {}

	# Act
	var result := _goal.get_priority(state)

	# Assert
	assert_float(result).is_equal(5.5)


# =============================================================================
# AFTER_PLAN_COMPLETE TESTS
# =============================================================================

func test_after_plan_complete_does_not_crash() -> void:
	# Arrange - default implementation is empty
	# Using null agent since base implementation ignores it

	# Act & Assert - should not throw
	_goal.after_plan_complete(null)


# =============================================================================
# MOCK GOAL TESTS (Testing Dynamic Behavior)
# =============================================================================

func test_mock_goal_dynamic_priority() -> void:
	# Arrange
	var mock_goal := auto_free(MockGoal.new()) as MockGoal
	mock_goal.dynamic_priority = func(state: Dictionary) -> float:
		var hunger: float = state.get(&"hunger", 0)
		return hunger * 2.0

	var low_hunger: Dictionary[StringName, Variant] = {&"hunger": 5}
	var high_hunger: Dictionary[StringName, Variant] = {&"hunger": 50}

	# Act & Assert
	assert_float(mock_goal.get_priority(low_hunger)).is_equal(10.0)
	assert_float(mock_goal.get_priority(high_hunger)).is_equal(100.0)


func test_mock_goal_relevance_check() -> void:
	# Arrange
	var mock_goal := auto_free(MockGoal.new()) as MockGoal
	mock_goal.desired_state = {&"has_food": true}
	mock_goal.relevance_check = func(state: Dictionary) -> bool:
		return state.get(&"is_hungry", false)

	var hungry_state: Dictionary[StringName, Variant] = {&"is_hungry": true}
	var full_state: Dictionary[StringName, Variant] = {&"is_hungry": false}

	# Act & Assert
	assert_bool(mock_goal.is_relevant(hungry_state)).is_true()
	assert_bool(mock_goal.is_relevant(full_state)).is_false()


func test_mock_goal_force_relevant_overrides_check() -> void:
	# Arrange
	var mock_goal := auto_free(MockGoal.new()) as MockGoal
	mock_goal.relevance_check = func(_s): return true
	mock_goal.force_relevant = false  # Force irrelevant

	var state: Dictionary[StringName, Variant] = {}

	# Act & Assert
	assert_bool(mock_goal.is_relevant(state)).is_false()


func test_mock_goal_tracks_completion_count() -> void:
	# Arrange
	var mock_goal := auto_free(MockGoal.new()) as MockGoal

	# Act
	mock_goal.after_plan_complete(null)
	mock_goal.after_plan_complete(null)
	mock_goal.after_plan_complete(null)

	# Assert
	assert_int(mock_goal.completion_count).is_equal(3)


func test_mock_goal_reset_clears_tracking() -> void:
	# Arrange
	var mock_goal := auto_free(MockGoal.new()) as MockGoal
	mock_goal.after_plan_complete(null)
	mock_goal.after_plan_complete(null)

	# Act
	mock_goal.reset()

	# Assert
	assert_int(mock_goal.completion_count).is_equal(0)


func test_mock_goal_on_complete_callback() -> void:
	# Arrange
	var mock_goal := auto_free(MockGoal.new()) as MockGoal
	var callback_invoked := [false]
	mock_goal.on_complete = func(_agent): callback_invoked[0] = true

	# Act
	mock_goal.after_plan_complete(null)

	# Assert
	assert_bool(callback_invoked[0]).is_true()


# =============================================================================
# EDGE CASES
# =============================================================================

func test_is_achieved_with_null_values() -> void:
	# Arrange
	_goal.desired_state = {&"target": null}
	var state: Dictionary[StringName, Variant] = {&"target": null}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_true()


func test_is_achieved_complex_value_types() -> void:
	# Arrange
	var target_pos := Vector3(10, 20, 30)
	_goal.desired_state = {&"position": target_pos}
	var state: Dictionary[StringName, Variant] = {&"position": Vector3(10, 20, 30)}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_true()


func test_multiple_conditions_partial_match_fails() -> void:
	# Arrange
	_goal.desired_state = {
		&"cond_a": true,
		&"cond_b": true,
		&"cond_c": true
	}
	var state: Dictionary[StringName, Variant] = {
		&"cond_a": true,
		&"cond_b": true,
		&"cond_c": false  # One wrong
	}

	# Act & Assert
	assert_bool(_goal.is_achieved(state)).is_false()
