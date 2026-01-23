## Feature tests for GOAP planning scenarios.
##
## Tests realistic multi-step planning scenarios including:[br]
## - Complex crafting chains[br]
## - Resource gathering[br]
## - Goal prioritization[br]
## - Dynamic preconditions
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

class FeatureTestAgent:
	extends GOAPAgent

	func _init() -> void:
		blackboard = GOAPTestHelper.create_state()


var _agent: FeatureTestAgent


func before_test() -> void:
	_agent = FeatureTestAgent.new()


func after_test() -> void:
	if _agent:
		_agent.free()
		_agent = null


# =============================================================================
# CRAFTING SCENARIOS
# =============================================================================

func test_scenario_craft_iron_sword() -> void:
	## Scenario: Craft an iron sword from scratch.
	## Chain: mine_ore -> smelt_ore -> craft_sword

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"CraftSword", {&"has_sword": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"MineOre", {}, {&"has_ore": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"SmeltOre", {&"has_ore": true}, {&"has_iron": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"CraftSword", {&"has_iron": true}, {&"has_sword": true}, 2.0)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	assert_int(plan.size()).is_equal(3)
	assert_str(plan[0].action_name).is_equal(&"MineOre")
	assert_str(plan[1].action_name).is_equal(&"SmeltOre")
	assert_str(plan[2].action_name).is_equal(&"CraftSword")
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, state, goal)).is_true()


func test_scenario_craft_with_partial_materials() -> void:
	## Scenario: Craft when some materials already owned.
	## Has ore, needs to smelt and craft.

	# Arrange
	var state := GOAPTestHelper.create_state({&"has_ore": true})
	var goal := GOAPTestHelper.create_mock_goal(&"CraftSword", {&"has_sword": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"MineOre", {}, {&"has_ore": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"SmeltOre", {&"has_ore": true}, {&"has_iron": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"CraftSword", {&"has_iron": true}, {&"has_sword": true}, 2.0)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert - should skip MineOre
	assert_int(plan.size()).is_equal(2)
	assert_str(plan[0].action_name).is_equal(&"SmeltOre")
	assert_str(plan[1].action_name).is_equal(&"CraftSword")


func test_scenario_multi_ingredient_crafting() -> void:
	## Scenario: Craft item requiring multiple ingredients.
	## Potion needs herb + water + bottle.

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"MakePotion", {&"has_potion": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"GatherHerb", {}, {&"has_herb": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"FetchWater", {}, {&"has_water": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"GetBottle", {}, {&"has_bottle": true}, 0.5),
		GOAPTestHelper.create_mock_action(&"BrewPotion",
			{&"has_herb": true, &"has_water": true, &"has_bottle": true},
			{&"has_potion": true},
			2.0
		)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, state, goal)).is_true()
	# Should have 4 actions (3 gather + 1 brew)
	assert_int(plan.size()).is_equal(4)


# =============================================================================
# SURVIVAL SCENARIOS
# =============================================================================

func test_scenario_survive_hunger() -> void:
	## Scenario: Agent is hungry and needs to eat.
	## Can hunt (needs weapon) or gather (no prereqs).

	# Arrange
	var state := GOAPTestHelper.create_state({&"is_hungry": true})
	var goal := GOAPTestHelper.create_mock_goal(&"Survive", {&"is_hungry": false})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"MakeSpear", {}, {&"has_weapon": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"Hunt", {&"has_weapon": true}, {&"has_food": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"Gather", {}, {&"has_food": true}, 4.0),
		GOAPTestHelper.create_mock_action(&"Eat", {&"has_food": true}, {&"is_hungry": false}, 1.0)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, state, goal)).is_true()
	# Should choose cheaper path: Gather (4) + Eat (1) = 5
	# vs MakeSpear (3) + Hunt (2) + Eat (1) = 6
	assert_float(GOAPTestHelper.calculate_plan_cost(plan)).is_equal(5.0)


func test_scenario_survive_with_weapon() -> void:
	## Scenario: Agent already has weapon, hunting becomes cheaper.

	# Arrange
	var state := GOAPTestHelper.create_state({
		&"is_hungry": true,
		&"has_weapon": true
	})
	var goal := GOAPTestHelper.create_mock_goal(&"Survive", {&"is_hungry": false})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"MakeSpear", {}, {&"has_weapon": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"Hunt", {&"has_weapon": true}, {&"has_food": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"Gather", {}, {&"has_food": true}, 4.0),
		GOAPTestHelper.create_mock_action(&"Eat", {&"has_food": true}, {&"is_hungry": false}, 1.0)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	# Should choose: Hunt (2) + Eat (1) = 3 (cheaper than Gather + Eat = 5)
	assert_float(GOAPTestHelper.calculate_plan_cost(plan)).is_equal(3.0)


# =============================================================================
# ECONOMY SCENARIOS
# =============================================================================

func test_scenario_earn_and_buy() -> void:
	## Scenario: Agent needs item from shop, must earn gold first.

	# Arrange
	var state := GOAPTestHelper.create_state({&"gold": 0})
	var goal := GOAPTestHelper.create_mock_goal(&"GetItem", {&"has_item": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"Work", {}, {&"gold": 100}, 5.0),
		GOAPTestHelper.create_mock_action(&"BuyItem", {&"gold": 100}, {&"has_item": true, &"gold": 0}, 1.0)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	assert_int(plan.size()).is_equal(2)
	assert_str(plan[0].action_name).is_equal(&"Work")
	assert_str(plan[1].action_name).is_equal(&"BuyItem")


func test_scenario_already_wealthy() -> void:
	## Scenario: Agent already has enough gold, skip work.

	# Arrange
	var state := GOAPTestHelper.create_state({&"gold": 100})
	var goal := GOAPTestHelper.create_mock_goal(&"GetItem", {&"has_item": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"Work", {}, {&"gold": 100}, 5.0),
		GOAPTestHelper.create_mock_action(&"BuyItem", {&"gold": 100}, {&"has_item": true, &"gold": 0}, 1.0)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert - should skip Work
	assert_int(plan.size()).is_equal(1)
	assert_str(plan[0].action_name).is_equal(&"BuyItem")


# =============================================================================
# MULTI-GOAL SCENARIOS
# =============================================================================

func test_scenario_prioritize_urgent_goal() -> void:
	## Scenario: Multiple goals, urgent one should be selected.

	# Arrange
	_agent.goals = [
		GOAPTestHelper.create_mock_goal(&"LongTerm", {&"has_house": true}),
		GOAPTestHelper.create_mock_goal(&"Urgent", {&"is_safe": true})
	]
	_agent.goals[0].priority = 1.0
	_agent.goals[1].priority = 10.0  # Higher priority

	# Act
	var selected := _agent._select_goal()

	# Assert
	assert_str(selected.goal_name).is_equal(&"Urgent")


func test_scenario_skip_achieved_goals() -> void:
	## Scenario: Don't pursue already-achieved goals.

	# Arrange - Safety is already achieved in blackboard
	_agent.blackboard.set_value(&"is_safe", true)
	_agent.goals = [
		GOAPTestHelper.create_mock_goal(&"Safe", {&"is_safe": true}),
		GOAPTestHelper.create_mock_goal(&"Wealth", {&"has_gold": true})
	]
	_agent.goals[0].priority = 10.0
	_agent.goals[1].priority = 1.0

	# Act
	var selected := _agent._select_goal()

	# Assert - Safety achieved, select Wealth
	assert_str(selected.goal_name).is_equal(&"Wealth")


# =============================================================================
# COMPLEX WORLD SCENARIOS
# =============================================================================

func test_scenario_build_shelter_full_chain() -> void:
	## Scenario: Complex shelter building with multiple resource chains.
	## Shelter needs: wood_planks + nails + roof_tiles
	## wood_planks needs: logs + saw
	## logs needs: axe
	## nails needs: iron
	## iron needs: ore + furnace
	## roof_tiles needs: clay

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"BuildShelter", {&"has_shelter": true})
	var actions: Array[GOAPAction] = [
		# Tools
		GOAPTestHelper.create_mock_action(&"GetAxe", {}, {&"has_axe": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"GetSaw", {}, {&"has_saw": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"GetFurnace", {}, {&"has_furnace": true}, 2.0),

		# Raw materials
		GOAPTestHelper.create_mock_action(&"ChopLogs", {&"has_axe": true}, {&"has_logs": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"MineOre", {}, {&"has_ore": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"GatherClay", {}, {&"has_clay": true}, 1.0),

		# Processed materials
		GOAPTestHelper.create_mock_action(&"SawPlanks", {&"has_logs": true, &"has_saw": true}, {&"has_planks": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"SmeltIron", {&"has_ore": true, &"has_furnace": true}, {&"has_iron": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"MakeNails", {&"has_iron": true}, {&"has_nails": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"MakeTiles", {&"has_clay": true}, {&"has_tiles": true}, 2.0),

		# Final assembly
		GOAPTestHelper.create_mock_action(&"BuildShelter",
			{&"has_planks": true, &"has_nails": true, &"has_tiles": true},
			{&"has_shelter": true},
			5.0
		)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	assert_bool(plan.size() > 0).is_true()
	assert_bool(GOAPTestHelper.verify_plan_achieves_goal(plan, state, goal)).is_true()

	# Verify final action is BuildShelter
	assert_str(plan[plan.size() - 1].action_name).is_equal(&"BuildShelter")


func test_scenario_with_existing_tools() -> void:
	## Scenario: Agent has some tools, plan should be shorter.

	# Arrange
	var state := GOAPTestHelper.create_state({
		&"has_axe": true,
		&"has_saw": true,
		&"has_furnace": true
	})
	var goal := GOAPTestHelper.create_mock_goal(&"BuildShelter", {&"has_shelter": true})
	var actions: Array[GOAPAction] = [
		GOAPTestHelper.create_mock_action(&"GetAxe", {}, {&"has_axe": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"GetSaw", {}, {&"has_saw": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"GetFurnace", {}, {&"has_furnace": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"ChopLogs", {&"has_axe": true}, {&"has_logs": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"MineOre", {}, {&"has_ore": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"GatherClay", {}, {&"has_clay": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"SawPlanks", {&"has_logs": true, &"has_saw": true}, {&"has_planks": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"SmeltIron", {&"has_ore": true, &"has_furnace": true}, {&"has_iron": true}, 3.0),
		GOAPTestHelper.create_mock_action(&"MakeNails", {&"has_iron": true}, {&"has_nails": true}, 1.0),
		GOAPTestHelper.create_mock_action(&"MakeTiles", {&"has_clay": true}, {&"has_tiles": true}, 2.0),
		GOAPTestHelper.create_mock_action(&"BuildShelter",
			{&"has_planks": true, &"has_nails": true, &"has_tiles": true},
			{&"has_shelter": true},
			5.0
		)
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert - should not include GetAxe, GetSaw, GetFurnace
	var action_names: Array[StringName] = []
	for action in plan:
		action_names.append(action.action_name)

	assert_bool(&"GetAxe" in action_names).is_false()
	assert_bool(&"GetSaw" in action_names).is_false()
	assert_bool(&"GetFurnace" in action_names).is_false()


# =============================================================================
# FAILURE SCENARIOS
# =============================================================================

func test_scenario_impossible_goal() -> void:
	## Scenario: Goal requires resource that cannot be obtained.

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"Impossible", {&"has_magic": true})
	var actions: Array[GOAPAction] = [
		# No action produces 'has_magic'
		GOAPTestHelper.create_mock_action(&"Work", {}, {&"has_gold": true}),
		GOAPTestHelper.create_mock_action(&"Rest", {}, {&"is_rested": true})
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	assert_array(plan).is_empty()


func test_scenario_blocked_by_missing_tool() -> void:
	## Scenario: Action requires tool that cannot be obtained.

	# Arrange
	var state := GOAPTestHelper.create_state()
	var goal := GOAPTestHelper.create_mock_goal(&"GetWood", {&"has_wood": true})
	var actions: Array[GOAPAction] = [
		# ChopTree needs axe, but no way to get axe
		GOAPTestHelper.create_mock_action(&"ChopTree", {&"has_axe": true}, {&"has_wood": true})
	]

	# Act
	var plan := GOAPPlanner.plan(state, actions, goal)

	# Assert
	assert_array(plan).is_empty()
