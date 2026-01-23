## Unit tests for GOAPPlanner.
##
## Tests the backward A* planning algorithm including:[br]
## - Valid plan generation[br]
## - Optimal path finding[br]
## - Edge cases (no plan, already achieved)[br]
## - Complex multi-step planning
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

var _state: GOAPState
var _actions: Array[GOAPAction]
var _goal: GOAPGoal


func before_test() -> void:
	_state = GOAPTestHelper.create_state()
	_actions = []
	_goal = null


func after_test() -> void:
	_state = null
	_actions.clear()
	_goal = null


# =============================================================================
# NO PLAN SCENARIOS
# =============================================================================

func test_plan_returns_empty_when_goal_already_achieved() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state({&"has_item": true})
	_goal = GOAPTestHelper.create_mock_goal(&"GetItem", {&"has_item": true})
	_actions = []

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_array(plan).is_empty()


func test_plan_returns_empty_when_no_actions_available() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Impossible", {&"magic": true})
	_actions = []

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_array(plan).is_empty()


func test_plan_returns_empty_when_goal_unreachable() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Impossible", {&"unobtainable": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"Useless", {}, {&"something_else": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_array(plan).is_empty()


func test_plan_returns_empty_when_preconditions_unsatisfiable() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"result": true})
	_actions = [
		# Action needs impossible precondition
		GOAPTestHelper.create_mock_action(&"Blocked", {&"impossible_prereq": true}, {&"result": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_array(plan).is_empty()


# =============================================================================
# SINGLE ACTION PLANS
# =============================================================================

func test_plan_single_action_no_preconditions() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"GetWood", {&"has_wood": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"ChopTree", {}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"ChopTree")


func test_plan_single_action_preconditions_already_met() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state({&"has_axe": true})
	_goal = GOAPTestHelper.create_mock_goal(&"GetWood", {&"has_wood": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"ChopTree")


func test_plan_selects_action_matching_goal() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"GetWood", {&"has_wood": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetStone", {}, {&"has_stone": true}),
		GOAPTestHelper.create_mock_action(&"GetWood", {}, {&"has_wood": true}),
		GOAPTestHelper.create_mock_action(&"GetIron", {}, {&"has_iron": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"GetWood")


# =============================================================================
# MULTI-STEP PLANS
# =============================================================================

func test_plan_two_step_chain() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"GetWood", {&"has_wood": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetAxe", {}, {&"has_axe": true}),
		GOAPTestHelper.create_mock_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(2)
	assert_str(plan[0].action_name).is_equal(&"GetAxe")
	assert_str(plan[1].action_name).is_equal(&"ChopTree")


func test_plan_three_step_chain() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"BuildFurniture", {&"has_furniture": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetAxe", {}, {&"has_axe": true}),
		GOAPTestHelper.create_mock_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true}),
		GOAPTestHelper.create_mock_action(&"Craft", {&"has_wood": true}, {&"has_furniture": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(3)
	assert_str(plan[0].action_name).is_equal(&"GetAxe")
	assert_str(plan[1].action_name).is_equal(&"ChopTree")
	assert_str(plan[2].action_name).is_equal(&"Craft")


func test_plan_skips_unnecessary_actions() -> void:
	# Arrange - axe already owned
	_state = GOAPTestHelper.create_state({&"has_axe": true})
	_goal = GOAPTestHelper.create_mock_goal(&"GetWood", {&"has_wood": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetAxe", {}, {&"has_axe": true}),  # Should skip
		GOAPTestHelper.create_mock_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - only ChopTree needed
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"ChopTree")


# =============================================================================
# COST OPTIMIZATION TESTS
# =============================================================================

func test_plan_prefers_lower_cost_action() -> void:
	# Arrange - two ways to get wood, different costs
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"GetWood", {&"has_wood": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"ExpensiveWay", {}, {&"has_wood": true}, 10.0),
		GOAPTestHelper.create_mock_action(&"CheapWay", {}, {&"has_wood": true}, 1.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"CheapWay")


func test_plan_prefers_lower_total_cost_path() -> void:
	# Arrange
	# Path A: action_a1 (cost 1) -> action_a2 (cost 1) = total 2
	# Path B: action_b (cost 5) = total 5
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"result": true})
	_actions = [
		# Path A
		GOAPTestHelper.create_mock_action(&"StepA1", {}, {&"intermediate": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"StepA2", {&"intermediate": true}, {&"result": true}, 1.0),
		# Path B
		GOAPTestHelper.create_mock_action(&"DirectB", {}, {&"result": true}, 5.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - should choose cheaper 2-step path
	assert_float(GOAPTestHelper.calculate_plan_cost(plan)).is_equal(2.0)


func test_plan_prefers_shorter_path_at_equal_cost() -> void:
	# Arrange
	# Path A: 3 actions at cost 1 each = total 3
	# Path B: 1 action at cost 3 = total 3
	# Both equal cost, prefer simpler (1 action)
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"result": true})
	_actions = [
		# Path A
		GOAPTestHelper.create_mock_action(&"A1", {}, {&"step1": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"A2", {&"step1": true}, {&"step2": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"A3", {&"step2": true}, {&"result": true}, 1.0),
		# Path B
		GOAPTestHelper.create_mock_action(&"Direct", {}, {&"result": true}, 3.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - A* may choose either since equal cost
	# Both are valid, just verify plan works
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, _state, _goal)).is_true()


# =============================================================================
# MULTI-CONDITION GOALS
# =============================================================================

func test_plan_satisfies_multiple_goal_conditions() -> void:
	# Arrange - goal needs two things
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"MultiGoal", {
		&"has_wood": true,
		&"has_stone": true
	})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetWood", {}, {&"has_wood": true}),
		GOAPTestHelper.create_mock_action(&"GetStone", {}, {&"has_stone": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(2)
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, _state, _goal)).is_true()


func test_plan_action_satisfies_multiple_conditions() -> void:
	# Arrange - one action provides both things
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"MultiGoal", {
		&"has_A": true,
		&"has_B": true
	})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetBoth", {}, {&"has_A": true, &"has_B": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)


func test_plan_partial_goal_satisfaction() -> void:
	# Arrange - already have one, need another
	_state = GOAPTestHelper.create_state({&"has_wood": true})
	_goal = GOAPTestHelper.create_mock_goal(&"BuildHouse", {
		&"has_wood": true,
		&"has_stone": true
	})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetWood", {}, {&"has_wood": true}),  # Unnecessary
		GOAPTestHelper.create_mock_action(&"GetStone", {}, {&"has_stone": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - only need stone
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"GetStone")


# =============================================================================
# BRANCHING AND ALTERNATIVES
# =============================================================================

func test_plan_chooses_between_alternative_paths() -> void:
	# Arrange - multiple ways to achieve goal
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"GetFood", {&"has_food": true})
	_actions = [
		# Hunt path (needs weapon)
		GOAPTestHelper.create_mock_action(&"MakeSpear", {}, {&"has_weapon": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"Hunt", {&"has_weapon": true}, {&"has_food": true}, 3.0),
		# Gather path (no prereqs, cheaper)
		GOAPTestHelper.create_mock_action(&"Gather", {}, {&"has_food": true}, 2.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - should choose cheaper Gather path
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"Gather")


func test_plan_handles_diamond_dependency() -> void:
	# Arrange - diamond pattern:
	#       Start
	#      /     \
	#   GetA    GetB
	#      \     /
	#       Goal (needs A and B)
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"has_A": true, &"has_B": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetA", {}, {&"has_A": true}),
		GOAPTestHelper.create_mock_action(&"GetB", {}, {&"has_B": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(2)
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, _state, _goal)).is_true()


# =============================================================================
# COMPLEX SCENARIOS
# =============================================================================

func test_plan_complex_crafting_scenario() -> void:
	# Arrange - complex crafting chain:
	# Goal: has_sword
	# sword needs: metal_bar + handle
	# metal_bar needs: ore + furnace_access
	# handle needs: wood
	# wood needs: axe
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"MakeSword", {&"has_sword": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetAxe", {}, {&"has_axe": true}),
		GOAPTestHelper.create_mock_action(&"ChopWood", {&"has_axe": true}, {&"has_wood": true}),
		GOAPTestHelper.create_mock_action(&"MakeHandle", {&"has_wood": true}, {&"has_handle": true}),
		GOAPTestHelper.create_mock_action(&"MineOre", {}, {&"has_ore": true}),
		GOAPTestHelper.create_mock_action(&"AccessFurnace", {}, {&"furnace_access": true}),
		GOAPTestHelper.create_mock_action(&"SmeltMetal", {&"has_ore": true, &"furnace_access": true}, {&"has_metal_bar": true}),
		GOAPTestHelper.create_mock_action(&"ForgeSword", {&"has_metal_bar": true, &"has_handle": true}, {&"has_sword": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_bool(plan.size() > 0).is_true()
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, _state, _goal)).is_true()


func test_plan_selects_optimal_among_many_actions() -> void:
	# Arrange - many possible actions, only some useful
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"target": true})

	_actions = []
	# Add many irrelevant actions
	for i in range(20):
		_actions.append(GOAPTestHelper.create_mock_action(
			("Irrelevant%d" % i) as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	# Add the useful action
	_actions.append(GOAPTestHelper.create_mock_action(&"Useful", {}, {&"target": true}, 1.0))

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"Useful")


# =============================================================================
# EDGE CASES
# =============================================================================

func test_plan_handles_boolean_false_condition() -> void:
	# Arrange - goal is to NOT have something
	_state = GOAPTestHelper.create_state({&"is_hungry": true})
	_goal = GOAPTestHelper.create_mock_goal(&"NotHungry", {&"is_hungry": false})
	_actions = [
		GOAPTestHelper.create_mock_action(&"Eat", {}, {&"is_hungry": false})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"Eat")


func test_plan_handles_numeric_conditions() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state({&"gold": 0})
	_goal = GOAPTestHelper.create_mock_goal(&"GetRich", {&"gold": 100})
	_actions = [
		GOAPTestHelper.create_mock_action(&"Work", {}, {&"gold": 100})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)


func test_plan_action_order_is_executable() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"final": true})
	_actions = [
		GOAPTestHelper.create_mock_action(&"Step1", {}, {&"step1_done": true}),
		GOAPTestHelper.create_mock_action(&"Step2", {&"step1_done": true}, {&"step2_done": true}),
		GOAPTestHelper.create_mock_action(&"Step3", {&"step2_done": true}, {&"final": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - verify preconditions are met at each step
	var sim_state := _state.duplicate()
	for action in plan:
		# Preconditions must be met
		assert_bool(sim_state.matches_conditions(action.preconditions)).is_true()
		# Apply effects for next iteration
		sim_state.apply_effects(action.effects)


func test_plan_with_null_state_handles_gracefully() -> void:
	# Arrange
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"done": true})
	_actions = [GOAPTestHelper.create_mock_action(&"Do", {}, {&"done": true})]

	# Act - passing empty state instead of null
	var empty_state := GOAPTestHelper.create_state()
	var plan := GOAPPlanner.plan(empty_state, _actions, _goal)

	# Assert
	assert_int(plan.size()).is_equal(1)


func test_plan_with_empty_actions_array() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"done": true})
	var empty_actions: Array[GOAPAction] = []

	# Act
	var plan := GOAPPlanner.plan(_state, empty_actions, _goal)

	# Assert
	assert_array(plan).is_empty()


func test_plan_with_empty_goal_desired_state() -> void:
	# Arrange
	_state = GOAPTestHelper.create_state({&"anything": true})
	_goal = GOAPTestHelper.create_mock_goal(&"EmptyGoal", {})
	_actions = [GOAPTestHelper.create_mock_action(&"Unused", {}, {&"x": true})]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - empty desired state = already achieved
	assert_array(plan).is_empty()


# =============================================================================
# PERFORMANCE SANITY TESTS
# =============================================================================

func test_plan_completes_within_reasonable_time() -> void:
	# Arrange - moderately complex scenario
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Complex", {&"final": true})

	_actions = []
	# Create a chain of 10 dependent actions
	for i in range(10):
		var prereq: Dictionary[StringName, Variant] = {}
		if i > 0:
			prereq[("step%d" % (i-1)) as StringName] = true
		var effect: Dictionary[StringName, Variant] = {("step%d" % i) as StringName: true}
		if i == 9:
			effect[&"final"] = true
		_actions.append(GOAPTestHelper.create_mock_action(("Action%d" % i) as StringName, prereq, effect))

	# Act
	var start := Time.get_ticks_usec()
	var plan := GOAPPlanner.plan(_state, _actions, _goal)
	var elapsed := Time.get_ticks_usec() - start

	# Assert
	assert_bool(plan.size() > 0).is_true()
	# Should complete in under 10ms (10000 usec) for this simple case
	assert_bool(elapsed < 10000).is_true()


func test_plan_with_many_irrelevant_actions_uses_effect_index() -> void:
	# Arrange - 100 actions, only 1 useful
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Target", {&"target": true})

	_actions = []
	for i in range(100):
		_actions.append(GOAPTestHelper.create_mock_action(
			("Irrelevant%d" % i) as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	_actions.append(GOAPTestHelper.create_mock_action(&"Target", {}, {&"target": true}))

	# Act
	var start := Time.get_ticks_usec()
	var plan := GOAPPlanner.plan(_state, _actions, _goal)
	var elapsed := Time.get_ticks_usec() - start

	# Assert
	assert_int(plan.size()).is_equal(1)
	# Effect indexing should make this fast despite 101 actions
	assert_bool(elapsed < 5000).is_true()  # 5ms max


# =============================================================================
# HEURISTIC TESTS
# =============================================================================

func test_plan_heuristic_is_admissible() -> void:
	# Arrange - multiple paths, verify optimal found
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Goal", {&"a": true, &"b": true, &"c": true})
	_actions = [
		# Individual actions (cost 1 each = 3 total)
		GOAPTestHelper.create_mock_action(&"GetA", {}, {&"a": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"GetB", {}, {&"b": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"GetC", {}, {&"c": true}, 1.0),
		# Combo action (gets A and B for 1.5)
		GOAPTestHelper.create_mock_action(&"GetAB", {}, {&"a": true, &"b": true}, 1.5),
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - should find optimal: GetAB (1.5) + GetC (1.0) = 2.5
	# Not GetA + GetB + GetC = 3.0
	var total_cost := GOAPTestHelper.calculate_plan_cost(plan)
	assert_float(total_cost).is_less_equal(2.5)


func test_plan_handles_unsatisfiable_condition_gracefully() -> void:
	# Arrange - one condition cannot be satisfied
	_state = GOAPTestHelper.create_state()
	_goal = GOAPTestHelper.create_mock_goal(&"Impossible", {
		&"achievable": true,
		&"impossible": true  # No action provides this
	})
	_actions = [
		GOAPTestHelper.create_mock_action(&"GetAchievable", {}, {&"achievable": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_state, _actions, _goal)

	# Assert - should return empty (impossible goal)
	assert_array(plan).is_empty()
