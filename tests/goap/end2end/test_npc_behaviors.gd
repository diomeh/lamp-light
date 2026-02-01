## End-to-end tests for complete NPC behavior loops.
##
## Tests realistic NPC scenarios including:[br]
## - Hunger → Find Food → Eat behavior loop[br]
## - Resource gathering cycles[br]
## - Multi-agent coordination
extends GdUnitTestSuite


# =============================================================================
# FIXTURES
# =============================================================================

## Test NPC agent for E2E testing.
class TestNPC:
	extends GOAPAgent

	func _init() -> void:
		blackboard = GOAPTestHelper.create_state()

	## Simulates a physics frame for the agent.
	func simulate_frame(delta: float) -> void:
		match _state:
			State.IDLE:
				pass  # Orchestrator handles
			State.PLANNING:
				pass  # Orchestrator handles
			State.PERFORMING:
				_process_performing(delta)


## Dynamic action that tracks execution.
class TrackedAction:
	extends GOAPAction

	var frames_to_complete: int = 1
	var _current_frame: int = 0
	var times_executed: int = 0
	var state_changes: Dictionary[StringName, Variant] = {}

	func execute(agent: GOAPAgent, _delta: float) -> ExecResult:
		_current_frame += 1

		if _current_frame >= frames_to_complete:
			times_executed += 1
			_current_frame = 0

			# Apply state changes
			for key in state_changes:
				agent.blackboard.set_value(key, state_changes[key])

			return ExecResult.SUCCESS

		return ExecResult.RUNNING

	func reset() -> void:
		_current_frame = 0
		times_executed = 0


## Dynamic goal that tracks completion.
class TrackedGoal:
	extends GOAPGoal

	var times_completed: int = 0
	var priority_func: Callable = Callable()
	var relevance_func: Callable = Callable()

	func get_priority(state: Dictionary[StringName, Variant]) -> float:
		if priority_func.is_valid():
			return priority_func.call(state)
		return priority

	func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
		if relevance_func.is_valid():
			return relevance_func.call(state)
		return true

	func after_plan_complete(_agent: GOAPAgent) -> void:
		times_completed += 1


var _npc: TestNPC


func before_test() -> void:
	_npc = auto_free(TestNPC.new()) as TestNPC


func after_test() -> void:
	_npc = null


# =============================================================================
# HELPERS
# =============================================================================

func _create_tracked_action(
	action_name: StringName,
	preconditions: Dictionary[StringName, Variant],
	effects: Dictionary[StringName, Variant],
	frames: int = 1
) -> TrackedAction:
	var action := TrackedAction.new()
	action.action_name = action_name
	action.preconditions = preconditions
	action.effects = effects
	action.frames_to_complete = frames
	action.state_changes = effects
	return action


func _create_tracked_goal(
	goal_name: StringName,
	desired: Dictionary[StringName, Variant],
	prio: float = 1.0
) -> TrackedGoal:
	var goal := TrackedGoal.new()
	goal.goal_name = goal_name
	goal.desired_state = desired
	goal.priority = prio
	return goal


func _run_npc_frames(frames: int, delta: float = 0.016) -> void:
	for i in range(frames):
		if _npc.needs_thinking():
			_npc.think()
		_npc.simulate_frame(delta)


# =============================================================================
# SURVIVAL BEHAVIOR LOOP
# =============================================================================

func test_e2e_hunger_food_eat_cycle() -> void:
	## Scenario: NPC becomes hungry, finds food, eats, becomes satisfied.
	## This tests a complete survival behavior loop.

	# Arrange - NPC is hungry
	_npc.blackboard = GOAPTestHelper.create_state({
		&"hunger": 80,
		&"has_food": false
	})

	# Goal: reduce hunger
	var survive_goal := _create_tracked_goal(&"Survive", {&"hunger": 0}, 10.0)
	survive_goal.relevance_func = func(state) -> bool:
		return state.get(&"hunger", 0) > 20

	_npc.goals = [survive_goal]

	# Actions: find food, then eat
	var find_food := _create_tracked_action(
		&"FindFood",
		{},
		{&"has_food": true},
		3  # Takes 3 frames
	)

	var eat := _create_tracked_action(
		&"Eat",
		{&"has_food": true},
		{&"hunger": 0, &"has_food": false},
		2  # Takes 2 frames
	)

	_npc.actions = [find_food, eat]

	# Act - run simulation
	_run_npc_frames(20)

	# Assert
	assert_int(_npc.blackboard.get_value(&"hunger")).is_equal(0)
	assert_int(find_food.times_executed).is_equal(1)
	assert_int(eat.times_executed).is_equal(1)
	assert_int(survive_goal.times_completed).is_equal(1)


func test_e2e_repeated_hunger_cycle() -> void:
	## Scenario: NPC completes hunger cycle, then hunger returns, cycle repeats.

	# Arrange
	_npc.blackboard = GOAPTestHelper.create_state({&"hunger": 50})

	var survive_goal := _create_tracked_goal(&"Survive", {&"hunger": 0}, 10.0)
	survive_goal.relevance_func = func(state) -> bool:
		return state.get(&"hunger", 0) > 0

	_npc.goals = [survive_goal]

	var find_eat := _create_tracked_action(
		&"FindAndEat",
		{},
		{&"hunger": 0},
		2
	)

	_npc.actions = [find_eat]

	# Act - complete first cycle
	_run_npc_frames(10)
	assert_int(survive_goal.times_completed).is_equal(1)

	# Simulate hunger returning
	_npc.blackboard.set_value(&"hunger", 60)

	# Complete second cycle
	_run_npc_frames(10)

	# Assert
	assert_int(survive_goal.times_completed).is_equal(2)
	assert_int(find_eat.times_executed).is_equal(2)


# =============================================================================
# RESOURCE GATHERING CYCLE
# =============================================================================

func test_e2e_gather_resources_craft_item() -> void:
	## Scenario: NPC gathers resources and crafts an item.

	# Arrange
	_npc.blackboard = GOAPTestHelper.create_state({
		&"wood": 0,
		&"stone": 0,
		&"has_tool": false
	})

	var craft_goal := _create_tracked_goal(&"CraftTool", {&"has_tool": true})
	_npc.goals = [craft_goal]

	var gather_wood := _create_tracked_action(
		&"GatherWood",
		{},
		{&"wood": 5},
		3
	)

	var gather_stone := _create_tracked_action(
		&"GatherStone",
		{},
		{&"stone": 3},
		2
	)

	var craft := _create_tracked_action(
		&"CraftTool",
		{&"wood": 5, &"stone": 3},
		{&"has_tool": true},
		4
	)

	_npc.actions = [gather_wood, gather_stone, craft]

	# Act
	_run_npc_frames(30)

	# Assert
	assert_bool(_npc.blackboard.get_value(&"has_tool")).is_true()
	assert_int(gather_wood.times_executed).is_equal(1)
	assert_int(gather_stone.times_executed).is_equal(1)
	assert_int(craft.times_executed).is_equal(1)


# =============================================================================
# PRIORITY-BASED BEHAVIOR
# =============================================================================

func test_e2e_urgent_goal_interrupts_low_priority() -> void:
	## Scenario: Low priority goal is in progress, urgent goal takes over.
	## Note: Current implementation doesn't support preemption,
	## so this tests priority selection between goal cycles.

	# Arrange
	_npc.blackboard = GOAPTestHelper.create_state({
		&"has_gold": false,
		&"is_safe": true
	})

	var wealth_goal := _create_tracked_goal(&"GetRich", {&"has_gold": true}, 1.0)
	var safety_goal := _create_tracked_goal(&"BeSafe", {&"is_safe": true}, 10.0)

	_npc.goals = [wealth_goal, safety_goal]

	var work := _create_tracked_action(&"Work", {}, {&"has_gold": true}, 3)
	var hide := _create_tracked_action(&"Hide", {}, {&"is_safe": true}, 1)

	_npc.actions = [work, hide]

	# Act - first cycle (safety already achieved)
	_run_npc_frames(10)

	# Assert - wealth goal selected since safety achieved
	assert_int(wealth_goal.times_completed).is_equal(1)

	# Make safety goal relevant again
	_npc.blackboard.set_value(&"is_safe", false)
	_npc.blackboard.set_value(&"has_gold", false)

	# Act - next cycle
	var data := {"selected_goal": null}
	_npc.goal_selected.connect(func(g): data.selected_goal = g, CONNECT_ONE_SHOT)
	_run_npc_frames(10)

	# Assert - safety (higher priority) selected first
	assert_str(data.selected_goal.goal_name).is_equal(&"BeSafe")

# =============================================================================
# COMPLEX MULTI-STEP BEHAVIOR
# =============================================================================

func test_e2e_complex_crafting_chain() -> void:
	## Scenario: NPC builds a house requiring multiple crafting steps.

	# Arrange
	_npc.blackboard = GOAPTestHelper.create_state({
		&"has_axe": false,
		&"has_wood": false,
		&"has_planks": false,
		&"has_house": false
	})

	var build_house := _create_tracked_goal(&"BuildHouse", {&"has_house": true})
	_npc.goals = [build_house]

	var get_axe := _create_tracked_action(&"GetAxe", {}, {&"has_axe": true}, 2)
	var chop_wood := _create_tracked_action(&"ChopWood", {&"has_axe": true}, {&"has_wood": true}, 3)
	var make_planks := _create_tracked_action(&"MakePlanks", {&"has_wood": true}, {&"has_planks": true}, 2)
	var build := _create_tracked_action(&"Build", {&"has_planks": true}, {&"has_house": true}, 5)

	_npc.actions = [get_axe, chop_wood, make_planks, build]

	# Act
	_run_npc_frames(50)

	# Assert
	assert_bool(_npc.blackboard.get_value(&"has_house")).is_true()
	assert_int(get_axe.times_executed).is_equal(1)
	assert_int(chop_wood.times_executed).is_equal(1)
	assert_int(make_planks.times_executed).is_equal(1)
	assert_int(build.times_executed).is_equal(1)


# =============================================================================
# FAILURE AND RECOVERY
# =============================================================================

func test_e2e_impossible_goal_graceful_handling() -> void:
	## Scenario: NPC has goal but no way to achieve it.

	# Arrange
	_npc.blackboard = GOAPTestHelper.create_state()

	var impossible := _create_tracked_goal(&"Impossible", {&"magic": true})
	var possible := _create_tracked_goal(&"Possible", {&"done": true}, 0.5)

	_npc.goals = [impossible, possible]

	# Only action achieves "done", not "magic"
	var do_something := _create_tracked_action(&"DoSomething", {}, {&"done": true})
	_npc.actions = [do_something]

	var plan_failed_count := {"count": 0}
	_npc.plan_failed.connect(func(_g): plan_failed_count.count += 1)

	# Act
	_run_npc_frames(20)

	# Assert - should fail impossible, succeed possible
	assert_int(plan_failed_count.count).is_equal(1)
	assert_int(possible.times_completed).is_equal(1)


# =============================================================================
# DYNAMIC GOAL PRIORITY
# =============================================================================

func test_e2e_dynamic_priority_based_on_state() -> void:
	## Scenario: Goal priority changes based on agent state.

	# Arrange
	_npc.blackboard = GOAPTestHelper.create_state({
		&"health": 100,
		&"gold": 0,
		&"healed": false,
		&"rich": false
	})

	var heal_goal := _create_tracked_goal(&"Heal", {&"healed": true})
	heal_goal.priority_func = func(state) -> float:
		var health: int = state.get(&"health", 100)
		# Priority increases as health decreases
		return (100 - health) / 10.0

	var wealth_goal := _create_tracked_goal(&"GetRich", {&"rich": true}, 5.0)

	_npc.goals = [heal_goal, wealth_goal]

	var heal := _create_tracked_action(&"Heal", {}, {&"healed": true})
	var work := _create_tracked_action(&"Work", {}, {&"rich": true})

	_npc.actions = [heal, work]

	# Act - at full health, wealth priority (5) > heal priority (0)
	var first_goal_data := {"goal": null}
	_npc.goal_selected.connect(func(g): first_goal_data.goal = g, CONNECT_ONE_SHOT)
	_run_npc_frames(10)

	assert_str(first_goal_data.goal.goal_name).is_equal(&"GetRich")

	# Reset and lower health
	_npc.blackboard.set_value(&"rich", false)
	_npc.blackboard.set_value(&"healed", false)
	_npc.blackboard.set_value(&"health", 20)  # heal priority now 8.0

	var second_goal_data := {"goal": null}
	_npc.goal_selected.connect(func(g): second_goal_data.goal = g, CONNECT_ONE_SHOT)
	_run_npc_frames(10)

	# Assert - heal now higher priority
	assert_str(second_goal_data.goal.goal_name).is_equal(&"Heal")


# =============================================================================
# PERFORMANCE TESTS
# =============================================================================

func test_e2e_many_actions_performance() -> void:
	## Scenario: Agent with many available actions can still plan quickly.

	# Arrange
	_npc.blackboard = GOAPTestHelper.create_state()
	var goal := _create_tracked_goal(&"Target", {&"target": true})
	_npc.goals = [goal]

	# Create many irrelevant actions
	var actions: Array[GOAPAction] = []
	for i in range(50):
		var action := TrackedAction.new()
		action.action_name = ("Irrelevant%d" % i) as StringName
		action.effects = {("effect%d" % i) as StringName: true}
		actions.append(action)

	# Add the useful action
	var target_action := _create_tracked_action(&"AchieveTarget", {}, {&"target": true})
	actions.append(target_action)
	_npc.actions = actions

	# Act
	var start := Time.get_ticks_usec()
	_run_npc_frames(10)
	var elapsed := Time.get_ticks_usec() - start

	# Assert
	assert_bool(goal.times_completed > 0).is_true()
	# Should complete in under 100ms even with many actions
	assert_bool(elapsed < 100000).is_true()
