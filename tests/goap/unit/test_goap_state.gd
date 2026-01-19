## Unit tests for GOAPState.
##
## Tests the blackboard/state container functionality including:[br]
## - Value get/set operations[br]
## - Signal emissions on change[br]
## - State duplication and isolation[br]
## - Condition matching[br]
## - Effect application[br]
## - Merge operations
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

var _state: GOAPState


func before_test() -> void:
	_state = GOAPState.new()


func after_test() -> void:
	_state = null


# =============================================================================
# INITIALIZATION TESTS
# =============================================================================

func test_init_empty_creates_empty_state() -> void:
	# Arrange & Act
	var state := GOAPState.new()

	# Assert
	assert_dict(state.to_dict()).is_empty()


func test_init_with_data_populates_state() -> void:
	# Arrange
	var initial: Dictionary[StringName, Variant] = {
		&"health": 100,
		&"has_weapon": true
	}

	# Act
	var state := GOAPState.new(initial)

	# Assert
	assert_int(state.get_value(&"health")).is_equal(100)
	assert_bool(state.get_value(&"has_weapon")).is_true()


# =============================================================================
# GET/SET VALUE TESTS
# =============================================================================

func test_set_value_stores_value() -> void:
	# Arrange & Act
	_state.set_value(&"test_key", 42)

	# Assert
	assert_int(_state.get_value(&"test_key")).is_equal(42)


func test_get_value_missing_key_returns_default() -> void:
	# Arrange - empty state

	# Act
	var result: String = _state.get_value(&"nonexistent", "default_value")

	# Assert
	assert_str(result).is_equal("default_value")


func test_get_value_missing_key_returns_null_when_no_default() -> void:
	# Arrange - empty state

	# Act
	var result: Variant = _state.get_value(&"nonexistent")

	# Assert
	assert_that(result).is_null()


func test_set_value_overwrites_existing() -> void:
	# Arrange
	_state.set_value(&"key", "old")

	# Act
	_state.set_value(&"key", "new")

	# Assert
	assert_str(_state.get_value(&"key")).is_equal("new")


func test_set_value_supports_various_types() -> void:
	# Arrange & Act
	_state.set_value(&"int_val", 42)
	_state.set_value(&"float_val", 3.14)
	_state.set_value(&"string_val", "test")
	_state.set_value(&"bool_val", true)
	_state.set_value(&"vector_val", Vector3(1, 2, 3))
	_state.set_value(&"array_val", [1, 2, 3])

	# Assert
	assert_int(_state.get_value(&"int_val")).is_equal(42)
	assert_float(_state.get_value(&"float_val")).is_equal_approx(3.14, 0.001)
	assert_str(_state.get_value(&"string_val")).is_equal("test")
	assert_bool(_state.get_value(&"bool_val")).is_true()
	assert_vector(_state.get_value(&"vector_val")).is_equal(Vector3(1, 2, 3))
	assert_array(_state.get_value(&"array_val")).is_equal([1, 2, 3])


# =============================================================================
# SIGNAL TESTS
# =============================================================================

func test_set_value_emits_state_changed_signal() -> void:
	# Arrange
	var data = {
		"signal_received": false,
		"received_key": &"",
		"received_new": null,
		"received_old": null,
	}

	_state.state_changed.connect(func(key, new_val, old_val):
		data["signal_received"] = true
		data["received_key"] = key
		data["received_new"] = new_val
		data["received_old"] = old_val
	)

	# Act
	_state.set_value(&"test", 100)

	# Assert
	assert_bool(data["signal_received"]).is_true()
	assert_str(data["received_key"]).is_equal(&"test")
	assert_int(data["received_new"]).is_equal(100)
	assert_that(data["received_old"]).is_null()

func test_set_value_same_value_does_not_emit_signal() -> void:
	# Arrange
	_state.set_value(&"key", 42)
	var signal_data := {"count": 0}
	_state.state_changed.connect(func(_k, _n, _o): signal_data["count"] += 1)

	# Act
	_state.set_value(&"key", 42)  # Same value

	# Assert
	assert_int(signal_data["count"]).is_equal(0)


func test_set_value_different_value_emits_signal() -> void:
	# Arrange
	_state.set_value(&"key", 42)
	var signal_data := {"count": 0}
	_state.state_changed.connect(func(_k, _n, _o): signal_data["count"] += 1)

	# Act
	_state.set_value(&"key", 100)  # Different value

	# Assert
	assert_int(signal_data["count"]).is_equal(1)


# =============================================================================
# HAS/ERASE VALUE TESTS
# =============================================================================

func test_has_value_returns_true_for_existing_key() -> void:
	# Arrange
	_state.set_value(&"exists", true)

	# Act & Assert
	assert_bool(_state.has_value(&"exists")).is_true()


func test_has_value_returns_false_for_missing_key() -> void:
	# Arrange - empty state

	# Act & Assert
	assert_bool(_state.has_value(&"missing")).is_false()


func test_erase_value_removes_key() -> void:
	# Arrange
	_state.set_value(&"to_remove", "value")

	# Act
	var result := _state.erase_value(&"to_remove")

	# Assert
	assert_bool(result).is_true()
	assert_bool(_state.has_value(&"to_remove")).is_false()


func test_erase_value_returns_false_for_missing_key() -> void:
	# Arrange - empty state

	# Act
	var result := _state.erase_value(&"nonexistent")

	# Assert
	assert_bool(result).is_false()


# =============================================================================
# DUPLICATION AND ISOLATION TESTS
# =============================================================================

func test_duplicate_creates_independent_copy() -> void:
	# Arrange
	_state.set_value(&"original", 100)

	# Act
	var copy := _state.duplicate()
	copy.set_value(&"original", 200)

	# Assert - original unchanged
	assert_int(_state.get_value(&"original")).is_equal(100)
	assert_int(copy.get_value(&"original")).is_equal(200)


func test_to_dict_returns_deep_copy() -> void:
	# Arrange
	_state.set_value(&"array", [1, 2, 3])

	# Act
	var dict := _state.to_dict()
	dict[&"array"].append(4)

	# Assert - original unchanged
	assert_array(_state.get_value(&"array")).is_equal([1, 2, 3])


func test_to_ref_returns_live_reference() -> void:
	# Arrange
	_state.set_value(&"key", 10)

	# Act
	var ref := _state.to_ref()
	ref[&"key"] = 20  # Modify through reference

	# Assert - original changed (this is intentional behavior)
	assert_int(_state.get_value(&"key")).is_equal(20)


# =============================================================================
# CONDITION MATCHING TESTS
# =============================================================================

func test_matches_conditions_all_match_returns_true() -> void:
	# Arrange
	_state.set_value(&"health", 100)
	_state.set_value(&"has_weapon", true)
	var conditions: Dictionary[StringName, Variant] = {
		&"health": 100,
		&"has_weapon": true
	}

	# Act & Assert
	assert_bool(_state.matches_conditions(conditions)).is_true()


func test_matches_conditions_missing_key_returns_false() -> void:
	# Arrange
	_state.set_value(&"health", 100)
	var conditions: Dictionary[StringName, Variant] = {
		&"health": 100,
		&"has_weapon": true  # Not in state
	}

	# Act & Assert
	assert_bool(_state.matches_conditions(conditions)).is_false()


func test_matches_conditions_wrong_value_returns_false() -> void:
	# Arrange
	_state.set_value(&"health", 50)
	var conditions: Dictionary[StringName, Variant] = {
		&"health": 100  # Different value
	}

	# Act & Assert
	assert_bool(_state.matches_conditions(conditions)).is_false()


func test_matches_conditions_empty_returns_true() -> void:
	# Arrange - any state
	_state.set_value(&"something", true)
	var empty: Dictionary[StringName, Variant] = {}

	# Act & Assert
	assert_bool(_state.matches_conditions(empty)).is_true()


func test_matches_state_compares_against_another_state() -> void:
	# Arrange
	_state.set_value(&"a", 1)
	_state.set_value(&"b", 2)

	var other := GOAPState.new({&"a": 1})  # Subset

	# Act & Assert
	assert_bool(_state.matches_state(other)).is_true()


# =============================================================================
# EFFECT APPLICATION TESTS
# =============================================================================

func test_apply_effects_sets_new_values() -> void:
	# Arrange
	var effects: Dictionary[StringName, Variant] = {
		&"new_key": "new_value",
		&"another": 42
	}

	# Act
	_state.apply_effects(effects)

	# Assert
	assert_str(_state.get_value(&"new_key")).is_equal("new_value")
	assert_int(_state.get_value(&"another")).is_equal(42)


func test_apply_effects_overwrites_existing() -> void:
	# Arrange
	_state.set_value(&"key", "old")
	var effects: Dictionary[StringName, Variant] = {&"key": "new"}

	# Act
	_state.apply_effects(effects)

	# Assert
	assert_str(_state.get_value(&"key")).is_equal("new")


# =============================================================================
# INCREMENT/DECREMENT TESTS
# =============================================================================

func test_increment_adds_to_existing_value() -> void:
	# Arrange
	_state.set_value(&"counter", 10)

	# Act
	_state.increment(&"counter", 5)

	# Assert
	assert_float(_state.get_value(&"counter")).is_equal(15.0)


func test_increment_initializes_missing_key_to_amount() -> void:
	# Arrange - key doesn't exist

	# Act
	_state.increment(&"new_counter", 7)

	# Assert
	assert_float(_state.get_value(&"new_counter")).is_equal(7.0)


func test_increment_default_amount_is_one() -> void:
	# Arrange
	_state.set_value(&"counter", 0)

	# Act
	_state.increment(&"counter")

	# Assert
	assert_float(_state.get_value(&"counter")).is_equal(1.0)


func test_decrement_subtracts_from_value() -> void:
	# Arrange
	_state.set_value(&"counter", 10)

	# Act
	_state.decrement(&"counter", 3)

	# Assert
	assert_float(_state.get_value(&"counter")).is_equal(7.0)


func test_increment_noop_on_non_numeric() -> void:
	# Arrange
	_state.set_value(&"string_val", "not a number")

	# Act
	_state.increment(&"string_val", 5)

	# Assert - unchanged
	assert_str(_state.get_value(&"string_val")).is_equal("not a number")


# =============================================================================
# APPEND VALUE TESTS
# =============================================================================

func test_append_value_creates_array_if_missing() -> void:
	# Arrange - key doesn't exist

	# Act
	_state.append_value(&"items", "first")

	# Assert
	assert_array(_state.get_value(&"items")).is_equal(["first"])


func test_append_value_adds_to_existing_array() -> void:
	# Arrange
	_state.set_value(&"items", ["a", "b"])

	# Act
	_state.append_value(&"items", "c")

	# Assert
	assert_array(_state.get_value(&"items")).is_equal(["a", "b", "c"])


func test_append_value_noop_if_already_present() -> void:
	# Arrange
	_state.set_value(&"items", ["a", "b"])

	# Act
	_state.append_value(&"items", "a")  # Already exists

	# Assert - unchanged
	assert_array(_state.get_value(&"items")).is_equal(["a", "b"])


func test_append_value_noop_on_non_array() -> void:
	# Arrange
	_state.set_value(&"not_array", 42)

	# Act
	_state.append_value(&"not_array", "value")

	# Assert - unchanged
	assert_int(_state.get_value(&"not_array")).is_equal(42)


# =============================================================================
# MERGE TESTS
# =============================================================================

func test_append_raw_merges_dictionary() -> void:
	# Arrange
	_state.set_value(&"existing", 1)
	var new_data: Dictionary[StringName, Variant] = {
		&"new_key": 2,
		&"existing": 10  # Overwrites
	}

	# Act
	_state.append_raw(new_data)

	# Assert
	assert_int(_state.get_value(&"existing")).is_equal(10)
	assert_int(_state.get_value(&"new_key")).is_equal(2)


func test_append_state_merges_another_state() -> void:
	# Arrange
	_state.set_value(&"a", 1)
	var other := GOAPState.new({&"b": 2})

	# Act
	_state.append(other)

	# Assert
	assert_int(_state.get_value(&"a")).is_equal(1)
	assert_int(_state.get_value(&"b")).is_equal(2)


func test_static_merge_creates_new_combined_state() -> void:
	# Arrange
	var state_a := GOAPState.new({&"a": 1})
	var state_b := GOAPState.new({&"b": 2, &"a": 10})  # b overwrites a

	# Act
	var merged := GOAPState.merge(state_a, state_b)

	# Assert
	assert_int(merged.get_value(&"a")).is_equal(10)  # b wins
	assert_int(merged.get_value(&"b")).is_equal(2)
	# Originals unchanged
	assert_int(state_a.get_value(&"a")).is_equal(1)


# =============================================================================
# UNSATISFIED CONDITIONS TESTS
# =============================================================================

func test_get_unsatisfied_conditions_returns_missing_keys() -> void:
	# Arrange
	_state.set_value(&"has_a", true)
	var conditions: Dictionary[StringName, Variant] = {
		&"has_a": true,
		&"has_b": true  # Missing
	}

	# Act
	var unsatisfied := _state.get_unsatisfied_conditions(conditions)

	# Assert
	assert_dict(unsatisfied).has_size(1)
	assert_bool(unsatisfied.has(&"has_b")).is_true()


func test_get_unsatisfied_conditions_returns_wrong_values() -> void:
	# Arrange
	_state.set_value(&"count", 5)
	var conditions: Dictionary[StringName, Variant] = {
		&"count": 10  # Wrong value
	}

	# Act
	var unsatisfied := _state.get_unsatisfied_conditions(conditions)

	# Assert
	assert_dict(unsatisfied).has_size(1)
	assert_int(unsatisfied[&"count"]).is_equal(10)


func test_get_unsatisfied_conditions_empty_when_all_satisfied() -> void:
	# Arrange
	_state.set_value(&"a", 1)
	_state.set_value(&"b", 2)
	var conditions: Dictionary[StringName, Variant] = {&"a": 1, &"b": 2}

	# Act
	var unsatisfied := _state.get_unsatisfied_conditions(conditions)

	# Assert
	assert_dict(unsatisfied).is_empty()


# =============================================================================
# CLEAR AND OVERRIDE TESTS
# =============================================================================

func test_clear_removes_all_values() -> void:
	# Arrange
	_state.set_value(&"a", 1)
	_state.set_value(&"b", 2)

	# Act
	_state.clear()

	# Assert
	assert_dict(_state.to_dict()).is_empty()


func test_override_replaces_entire_state() -> void:
	# Arrange
	_state.set_value(&"old", 1)
	var new_data: Dictionary[StringName, Variant] = {&"new": 2}

	# Act
	_state.override(new_data)

	# Assert
	assert_bool(_state.has_value(&"old")).is_false()
	assert_int(_state.get_value(&"new")).is_equal(2)


func test_override_creates_deep_copy() -> void:
	# Arrange
	var new_data: Dictionary[StringName, Variant] = {&"arr": [1, 2, 3]}
	_state.override(new_data)

	# Act - modify original
	new_data[&"arr"].append(4)

	# Assert - state unchanged
	assert_array(_state.get_value(&"arr")).is_equal([1, 2, 3])
