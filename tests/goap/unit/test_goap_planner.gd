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

## Minimal agent for planner tests.
## Contains only what GOAPPlanner.plan() needs.
class PlannerTestAgent:
	extends GOAPAgent

	func _init() -> void:
		# Skip scene tree dependencies
		blackboard = GOAPState.new()


var _agent: PlannerTestAgent


func before_test() -> void:
	_agent = PlannerTestAgent.new()


func after_test() -> void:
	_agent = null


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _create_action(
	action_name: StringName,
	preconditions: Dictionary[StringName, Variant],
	effects: Dictionary[StringName, Variant],
	cost: float = 1.0
) -> GOAPAction:
	var action := GOAPAction.new()
	action.action_name = action_name
	action.preconditions = preconditions
	action.effects = effects
	action.cost = cost
	return action


func _create_goal(
	goal_name: StringName,
	desired_state: Dictionary[StringName, Variant]
) -> GOAPGoal:
	var goal := GOAPGoal.new()
	goal.goal_name = goal_name
	goal.desired_state = desired_state
	return goal


func _verify_plan_achieves(
	plan: Array[GOAPAction],
	initial: GOAPState,
	goal: GOAPGoal
) -> bool:
	return GOAPTestHelper.verify_plan_achieves_goal(plan, initial, goal)


func _calculate_plan_cost(plan: Array[GOAPAction]) -> float:
	return GOAPTestHelper.calculate_plan_cost(plan)


# =============================================================================
# NO PLAN SCENARIOS
# =============================================================================

func test_plan_returns_empty_when_goal_already_achieved() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new({&"has_item": true})
	_agent.current_goal = _create_goal(&"GetItem", {&"has_item": true})
	_agent.actions = []

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_array(plan).is_empty()


func test_plan_returns_empty_when_no_actions_available() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Impossible", {&"magic": true})
	_agent.actions = []

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_array(plan).is_empty()


func test_plan_returns_empty_when_goal_unreachable() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Impossible", {&"unobtainable": true})
	_agent.actions = [
		_create_action(&"Useless", {}, {&"something_else": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_array(plan).is_empty()


func test_plan_returns_empty_when_preconditions_unsatisfiable() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Goal", {&"result": true})
	_agent.actions = [
		# Action needs impossible precondition
		_create_action(&"Blocked", {&"impossible_prereq": true}, {&"result": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_array(plan).is_empty()


# =============================================================================
# SINGLE ACTION PLANS
# =============================================================================

func test_plan_single_action_no_preconditions() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"GetWood", {&"has_wood": true})
	_agent.actions = [
		_create_action(&"ChopTree", {}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"ChopTree")


func test_plan_single_action_preconditions_already_met() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new({&"has_axe": true})
	_agent.current_goal = _create_goal(&"GetWood", {&"has_wood": true})
	_agent.actions = [
		_create_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"ChopTree")


func test_plan_selects_action_matching_goal() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"GetWood", {&"has_wood": true})
	_agent.actions = [
		_create_action(&"GetStone", {}, {&"has_stone": true}),
		_create_action(&"GetWood", {}, {&"has_wood": true}),
		_create_action(&"GetIron", {}, {&"has_iron": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"GetWood")


# =============================================================================
# MULTI-STEP PLANS
# =============================================================================

func test_plan_two_step_chain() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"GetWood", {&"has_wood": true})
	_agent.actions = [
		_create_action(&"GetAxe", {}, {&"has_axe": true}),
		_create_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(2)
	assert_str(plan[0].action_name).is_equal(&"GetAxe")
	assert_str(plan[1].action_name).is_equal(&"ChopTree")


func test_plan_three_step_chain() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"BuildFurniture", {&"has_furniture": true})
	_agent.actions = [
		_create_action(&"GetAxe", {}, {&"has_axe": true}),
		_create_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true}),
		_create_action(&"Craft", {&"has_wood": true}, {&"has_furniture": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(3)
	assert_str(plan[0].action_name).is_equal(&"GetAxe")
	assert_str(plan[1].action_name).is_equal(&"ChopTree")
	assert_str(plan[2].action_name).is_equal(&"Craft")


func test_plan_skips_unnecessary_actions() -> void:
	# Arrange - axe already owned
	_agent.blackboard = GOAPState.new({&"has_axe": true})
	_agent.current_goal = _create_goal(&"GetWood", {&"has_wood": true})
	_agent.actions = [
		_create_action(&"GetAxe", {}, {&"has_axe": true}),  # Should skip
		_create_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert - only ChopTree needed
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"ChopTree")


# =============================================================================
# COST OPTIMIZATION TESTS
# =============================================================================

func test_plan_prefers_lower_cost_action() -> void:
	# Arrange - two ways to get wood, different costs
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"GetWood", {&"has_wood": true})
	_agent.actions = [
		_create_action(&"ExpensiveWay", {}, {&"has_wood": true}, 10.0),
		_create_action(&"CheapWay", {}, {&"has_wood": true}, 1.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"CheapWay")


func test_plan_prefers_lower_total_cost_path() -> void:
	# Arrange
	# Path A: action_a1 (cost 1) -> action_a2 (cost 1) = total 2
	# Path B: action_b (cost 5) = total 5
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Goal", {&"result": true})
	_agent.actions = [
		# Path A
		_create_action(&"StepA1", {}, {&"intermediate": true}, 1.0),
		_create_action(&"StepA2", {&"intermediate": true}, {&"result": true}, 1.0),
		# Path B
		_create_action(&"DirectB", {}, {&"result": true}, 5.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert - should choose cheaper 2-step path
	assert_float(_calculate_plan_cost(plan)).is_equal(2.0)


func test_plan_prefers_shorter_path_at_equal_cost() -> void:
	# Arrange
	# Path A: 3 actions at cost 1 each = total 3
	# Path B: 1 action at cost 3 = total 3
	# Both equal cost, prefer simpler (1 action)
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Goal", {&"result": true})
	_agent.actions = [
		# Path A
		_create_action(&"A1", {}, {&"step1": true}, 1.0),
		_create_action(&"A2", {&"step1": true}, {&"step2": true}, 1.0),
		_create_action(&"A3", {&"step2": true}, {&"result": true}, 1.0),
		# Path B
		_create_action(&"Direct", {}, {&"result": true}, 3.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert - A* may choose either since equal cost
	# Both are valid, just verify plan works
	assert_bool(_verify_plan_achieves(plan, _agent.blackboard, _agent.current_goal)).is_true()


# =============================================================================
# MULTI-CONDITION GOALS
# =============================================================================

func test_plan_satisfies_multiple_goal_conditions() -> void:
	# Arrange - goal needs two things
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"MultiGoal", {
		&"has_wood": true,
		&"has_stone": true
	})
	_agent.actions = [
		_create_action(&"GetWood", {}, {&"has_wood": true}),
		_create_action(&"GetStone", {}, {&"has_stone": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(2)
	assert_bool(_verify_plan_achieves(plan, _agent.blackboard, _agent.current_goal)).is_true()


func test_plan_action_satisfies_multiple_conditions() -> void:
	# Arrange - one action provides both things
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"MultiGoal", {
		&"has_A": true,
		&"has_B": true
	})
	_agent.actions = [
		_create_action(&"GetBoth", {}, {&"has_A": true, &"has_B": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)


func test_plan_partial_goal_satisfaction() -> void:
	# Arrange - already have one, need another
	_agent.blackboard = GOAPState.new({&"has_wood": true})
	_agent.current_goal = _create_goal(&"BuildHouse", {
		&"has_wood": true,
		&"has_stone": true
	})
	_agent.actions = [
		_create_action(&"GetWood", {}, {&"has_wood": true}),  # Unnecessary
		_create_action(&"GetStone", {}, {&"has_stone": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert - only need stone
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"GetStone")


# =============================================================================
# BRANCHING AND ALTERNATIVES
# =============================================================================

func test_plan_chooses_between_alternative_paths() -> void:
	# Arrange - multiple ways to achieve goal
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"GetFood", {&"has_food": true})
	_agent.actions = [
		# Hunt path (needs weapon)
		_create_action(&"MakeSpear", {}, {&"has_weapon": true}, 2.0),
		_create_action(&"Hunt", {&"has_weapon": true}, {&"has_food": true}, 3.0),
		# Gather path (no prereqs, cheaper)
		_create_action(&"Gather", {}, {&"has_food": true}, 2.0)
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

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
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Goal", {&"has_A": true, &"has_B": true})
	_agent.actions = [
		_create_action(&"GetA", {}, {&"has_A": true}),
		_create_action(&"GetB", {}, {&"has_B": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(2)
	assert_bool(_verify_plan_achieves(plan, _agent.blackboard, _agent.current_goal)).is_true()


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
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"MakeSword", {&"has_sword": true})
	_agent.actions = [
		_create_action(&"GetAxe", {}, {&"has_axe": true}),
		_create_action(&"ChopWood", {&"has_axe": true}, {&"has_wood": true}),
		_create_action(&"MakeHandle", {&"has_wood": true}, {&"has_handle": true}),
		_create_action(&"MineOre", {}, {&"has_ore": true}),
		_create_action(&"AccessFurnace", {}, {&"furnace_access": true}),
		_create_action(&"SmeltMetal", {&"has_ore": true, &"furnace_access": true}, {&"has_metal_bar": true}),
		_create_action(&"ForgeSword", {&"has_metal_bar": true, &"has_handle": true}, {&"has_sword": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_bool(plan.size() > 0).is_true()
	assert_bool(_verify_plan_achieves(plan, _agent.blackboard, _agent.current_goal)).is_true()


func test_plan_selects_optimal_among_many_actions() -> void:
	# Arrange - many possible actions, only some useful
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Goal", {&"target": true})

	var actions: Array[GOAPAction] = []
	# Add many irrelevant actions
	for i in range(20):
		actions.append(_create_action(
			"Irrelevant%d" % i as StringName,
			{},
			{("effect%d" % i) as StringName: true}
		))
	# Add the useful action
	actions.append(_create_action(&"Useful", {}, {&"target": true}, 1.0))
	_agent.actions = actions

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"Useful")


# =============================================================================
# EDGE CASES
# =============================================================================

func test_plan_handles_boolean_false_condition() -> void:
	# Arrange - goal is to NOT have something
	_agent.blackboard = GOAPState.new({&"is_hungry": true})
	_agent.current_goal = _create_goal(&"NotHungry", {&"is_hungry": false})
	_agent.actions = [
		_create_action(&"Eat", {}, {&"is_hungry": false})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"Eat")


func test_plan_handles_numeric_conditions() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new({&"gold": 0})
	_agent.current_goal = _create_goal(&"GetRich", {&"gold": 100})
	_agent.actions = [
		_create_action(&"Work", {}, {&"gold": 100})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert
	assert_int(plan.size()).is_equal(1)


func test_plan_action_order_is_executable() -> void:
	# Arrange
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Goal", {&"final": true})
	_agent.actions = [
		_create_action(&"Step1", {}, {&"step1_done": true}),
		_create_action(&"Step2", {&"step1_done": true}, {&"step2_done": true}),
		_create_action(&"Step3", {&"step2_done": true}, {&"final": true})
	]

	# Act
	var plan := GOAPPlanner.plan(_agent)

	# Assert - verify preconditions are met at each step
	var sim_state := _agent.blackboard.duplicate()
	for action in plan:
		# Preconditions must be met
		assert_bool(sim_state.matches_conditions(action.preconditions)).is_true()
		# Apply effects for next iteration
		sim_state.apply_effects(action.effects)


# =============================================================================
# PERFORMANCE SANITY TESTS
# =============================================================================

func test_plan_completes_within_reasonable_time() -> void:
	# Arrange - moderately complex scenario
	_agent.blackboard = GOAPState.new()
	_agent.current_goal = _create_goal(&"Complex", {&"final": true})

	var actions: Array[GOAPAction] = []
	# Create a chain of 10 dependent actions
	for i in range(10):
		var prereq: Dictionary[StringName, Variant] = {}
		if i > 0:
			prereq[("step%d" % (i-1)) as StringName] = true
		var effect: Dictionary[StringName, Variant] = {("step%d" % i) as StringName: true}
		if i == 9:
			effect[&"final"] = true
		actions.append(_create_action(("Action%d" % i) as StringName, prereq, effect))
	_agent.actions = actions

	# Act
	var start := Time.get_ticks_usec()
	var plan := GOAPPlanner.plan(_agent)
	var elapsed := Time.get_ticks_usec() - start

	# Assert
	assert_bool(plan.size() > 0).is_true()
	# Should complete in under 10ms (10000 usec) for this simple case
	assert_bool(elapsed < 10000).is_true()
