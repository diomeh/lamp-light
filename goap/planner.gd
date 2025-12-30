extends Node

## GOAP planner that uses A* search to find the optimal sequence of actions
## to achieve a goal from a given world state.


## Internal node class used during A* pathfinding.
## Represents a state in the search space with its associated action and cost.
class PlanNode:
	## The world state at this node
	var state: GOAPState
	## The action that led to this state (null for start node)
	var action: GOAPAction
	## The parent node in the search path
	var parent: PlanNode
	## The cumulative cost to reach this node
	var cost: float

	func _init(
		s: GOAPState,
		a: GOAPAction,
		p: PlanNode,
		c: float
	) -> void:
		state = s
		action = a
		parent = p
		cost = c


## Creates an action plan to achieve the given goal from the current world state.
## Uses A* algorithm to find the lowest-cost sequence of actions.
## Returns an array of actions in execution order, or an empty array if no plan exists.
func plan(agent: GOAPAgent) -> Array[GOAPAction]:
	var available_actions := agent.actions
	var world_state := agent.world_state
	var goal := agent.current_goal

	# Filter actions that can be performed
	var usable_actions: Array[GOAPAction] = []
	for action in available_actions:
		if action.can_perform(agent):
			usable_actions.append(action)

	# A* planning
	var open_list: Array[PlanNode] = []
	var closed_list: Array[GOAPState] = []

	# Start node
	var start_node: PlanNode = PlanNode.new(world_state, null, null, 0.0)
	open_list.append(start_node)

	while open_list.size() > 0:
		# Get node with lowest cost
		var current: PlanNode = _get_lowest_cost_node(open_list)
		open_list.erase(current)

		# Check if goal is achieved
		if goal.is_achieved(current.state):
			return _reconstruct_plan(current)

		closed_list.append(current.state)

		# Expand neighbors
		for action in usable_actions:
			if action.check_preconditions(current.state):
				var new_state: GOAPState = action.apply_effects(current.state)

				# Skip if already evaluated
				if _state_in_list(new_state, closed_list):
					continue

				var new_cost: float = current.cost + action.cost
				var neighbor: PlanNode = PlanNode.new(new_state, action, current, new_cost)

				# Check if this path is better
				var existing: PlanNode = _find_node_with_state(open_list, new_state)
				if existing == null:
					open_list.append(neighbor)
				elif new_cost < existing.cost:
					open_list.erase(existing)
					open_list.append(neighbor)

	# No plan found
	return []


## Finds the node with the lowest cost in the given list.
## Returns the PlanNode with minimum cost.
func _get_lowest_cost_node(nodes: Array[PlanNode]) -> PlanNode:
	var lowest: PlanNode = nodes[0]
	for node in nodes:
		if node.cost < lowest.cost:
			lowest = node
	return lowest


## Checks if a given state already exists in the list of states.
## Returns true if found, false otherwise.
func _state_in_list(state: GOAPState, list: Array[GOAPState]) -> bool:
	for s in list:
		if s.matches_state(state):
			return true
	return false


## Finds a node with the given state in the list of nodes.
## Returns the matching PlanNode or null if not found.
func _find_node_with_state(nodes: Array[PlanNode], state: GOAPState) -> PlanNode:
	for node in nodes:
		if node.state.matches_state(state):
			return node
	return null


## Reconstructs the action sequence by walking back from the goal node to the start.
## Returns an array of actions in execution order.
func _reconstruct_plan(end_node: PlanNode) -> Array[GOAPAction]:
	var plan_arr: Array[GOAPAction] = []
	var current: PlanNode = end_node

	while current != null and current.action != null:
		plan_arr.push_front(current.action)
		current = current.parent

	return plan_arr
