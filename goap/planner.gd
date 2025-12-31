extends Node

## GOAP planner using backward (regressive) A* search.
## Plans by working backwards from the goal state to find actions that satisfy
## unsatisfied conditions.


## Internal node class used during backward A* pathfinding.
## Represents unsatisfied conditions that need to be met.
class PlanNode:
	## Dictionary of conditions that still need to be satisfied
	## Key: condition name, Value: required value
	var unsatisfied: Dictionary[String, Variant]
	## The action that will satisfy some conditions (null for goal node)
	var action: GOAPAction
	## The parent node in the search path (closer to goal)
	var parent: PlanNode
	## The cumulative cost from this node to the goal
	var g_cost: float
	## Heuristic estimate of cost to reach initial state
	var h_cost: float
	## Total estimated cost (g + h)
	var f_cost: float

	func _init(
		u: Dictionary[String, Variant],
		a: GOAPAction,
		p: PlanNode,
		g: float,
		h: float
	) -> void:
		unsatisfied = u
		action = a
		parent = p
		g_cost = g
		h_cost = h
		f_cost = g + h

	## Creates a unique key for this node's unsatisfied conditions
	## Used for detecting duplicate states in the search
	## TODO: this coould be replaced by Dictionary.hash() depending on implementation
	func get_state_key() -> String:
		var keys: Array = unsatisfied.keys()
		keys.sort()
		var parts: Array[String] = []
		for key in keys:
			parts.append("%s=%s" % [key, str(unsatisfied[key])])
		return ",".join(parts)


## Creates an action plan to achieve the given goal from the current world state.
## Uses backward A* algorithm to find the lowest-cost sequence of actions.
## Returns an array of actions in execution order, or an empty array if no plan exists.
func plan(agent: GOAPAgent) -> Array[GOAPAction]:
	var available_actions := agent.actions
	var current_state := agent.get_full_state()
	var goal := agent.current_goal

	# Filter actions that can be performed at runtime
	var usable_actions: Array[GOAPAction] = []
	for action in available_actions:
		if action.can_perform(agent):
			usable_actions.append(action)

	# Start with goal's desired state as unsatisfied conditions
	# Only check current_state once at the start to determine initial unsatisfied set
	var goal_conditions: Dictionary[String, Variant] = goal.desired_state.duplicate()
	var initial_unsatisfied := current_state.get_unsatisfied_conditions(goal_conditions)

	# If goal is already achieved, no plan needed
	if initial_unsatisfied.is_empty():
		return []

	# Backward A* planning
	var open_list: Array[PlanNode] = []
	var closed_set: Dictionary[String, bool] = {} # Set of visited state keys

	# Start node represents the goal state with unsatisfied conditions
	var start_h := _calculate_heuristic(initial_unsatisfied, usable_actions)
	var start_node := PlanNode.new(initial_unsatisfied, null, null, 0.0, start_h)
	open_list.append(start_node)

	while open_list.size() > 0:
		# Get node with lowest f_cost
		var current := _get_lowest_cost_node(open_list)
		open_list.erase(current)

		var state_key := current.get_state_key()

		# Skip if already visited
		if closed_set.has(state_key):
			continue

		closed_set[state_key] = true

		# Terminate when all conditions are satisfied (unsatisfied == ∅)
		if current.unsatisfied.is_empty():
			return _reconstruct_plan(current)

		# Find actions whose effects can satisfy at least one unsatisfied condition
		for action in usable_actions:
			if not action.satisfies_any(current.unsatisfied):
				continue

			var new_unsatisfied := action.regress_conditions(current.unsatisfied, current_state)
			var new_state_key := _dict_to_key(new_unsatisfied)
			if closed_set.has(new_state_key):
				continue

			var new_g := current.g_cost + action.cost
			var new_h := _calculate_heuristic(new_unsatisfied, usable_actions)
			var neighbor := PlanNode.new(new_unsatisfied, action, current, new_g, new_h)

			# Check if we already have a better path to this state
			# Replace only if new_g < old_g
			var existing := _find_node_with_key(open_list, new_state_key)
			if existing == null:
				open_list.append(neighbor)
			elif new_g < existing.g_cost:
				open_list.erase(existing)
				open_list.append(neighbor)

	# No plan found
	return []


## Calculates admissible heuristic estimate for remaining cost.
## Uses max of minimum costs when an action can satisfy multiple conditions,
## ensuring the heuristic never overestimates the true remaining cost.
func _calculate_heuristic(
	unsatisfied: Dictionary[String, Variant],
	actions: Array[GOAPAction]
) -> float:
	if unsatisfied.is_empty():
		return 0.0

	# Build a map of condition -> min cost to satisfy it
	var condition_min_costs: Dictionary[String, float] = {}
	for key in unsatisfied:
		condition_min_costs[key] = INF
		var required_value: Variant = unsatisfied[key]

		for action in actions:
			if action.effects.has(key) and action.effects[key] == required_value:
				condition_min_costs[key] = min(condition_min_costs[key], action.cost)

	# For each action, check how many unsatisfied conditions it can satisfy
	# If one action satisfies multiple conditions, we use max (not sum) for those
	# to maintain admissibility
	var max_h: float = 0.0

	for action in actions:
		var conditions_satisfied: Array[String] = []
		for key in unsatisfied:
			var required_value: Variant = unsatisfied[key]
			if action.effects.has(key) and action.effects[key] == required_value:
				conditions_satisfied.append(key)

		if conditions_satisfied.size() > 1:
			# This action satisfies multiple conditions - use max for admissibility
			for key in conditions_satisfied:
				max_h = max(max_h, action.cost)

	# Calculate sum of independent conditions (not covered by multi-effect actions)
	# For safety, use max heuristic: max of all individual min costs
	# This is always admissible since we need at least one action
	for key in condition_min_costs:
		if condition_min_costs[key] == INF:
			# No action can satisfy this - problem is unsolvable
			# Return large value but don't make it infinite to allow exploration
			return 10000.0
		max_h = max(max_h, condition_min_costs[key])

	return max_h


## Finds the node with the lowest f_cost in the given list.
## Returns the PlanNode with minimum f_cost.
## Tie-breaker uses g_cost (prefer more concrete plans) which does not increase f.
func _get_lowest_cost_node(nodes: Array[PlanNode]) -> PlanNode:
	var lowest: PlanNode = nodes[0]
	for node in nodes:
		if node.f_cost < lowest.f_cost:
			lowest = node
		elif node.f_cost == lowest.f_cost and node.g_cost > lowest.g_cost:
			# Tie-breaker: prefer higher g_cost (more work done, closer to solution)
			# This does not increase f_cost
			lowest = node
	return lowest


## Converts a dictionary to a string key for hashing.
func _dict_to_key(dict: Dictionary[String, Variant]) -> String:
	var keys: Array = dict.keys()
	keys.sort()
	var parts: Array[String] = []
	for key in keys:
		parts.append("%s=%s" % [key, str(dict[key])])
	return ",".join(parts)


## Finds a node with the given state key in the list.
## Returns the matching PlanNode or null if not found.
func _find_node_with_key(nodes: Array[PlanNode], state_key: String) -> PlanNode:
	for node in nodes:
		if node.get_state_key() == state_key:
			return node
	return null


## Reconstructs the action sequence by walking from the start to the goal.
## Since we planned backwards, the parent chain goes from initial state to goal,
## so actions are already in execution order.
func _reconstruct_plan(start_node: PlanNode) -> Array[GOAPAction]:
	var plan_arr: Array[GOAPAction] = []
	var current: PlanNode = start_node

	# Walk from initial state toward goal, collecting actions
	while current != null and current.action != null:
		plan_arr.append(current.action)
		current = current.parent

	return plan_arr
