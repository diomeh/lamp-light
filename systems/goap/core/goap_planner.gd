## GOAP planner autoload using backward (regressive) A* search.
##
## Provides autoload singleton access to planning algorithm.[br]
## All planning methods are and do not require scene tree access.[br][br]
##
## [b]Algorithm:[/b] Backward A* with state-space regression[br]
## [b]Complexity:[/b] O(b^d) where b = branching factor, d = plan depth[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## # Called automatically by GOAPAgent, but can be used directly:
## var plan: Array[GOAPAction] = GOAPPlanner.plan(state, actions, goal)
## if plan.is_empty():
##     print("No valid plan found!")
## [/codeblock]
## [br]
## See also: [GOAPAgent], [GOAPAction], [GOAPGoal]
extends Node


## Internal node for A* search representing a partial plan state.
##
## Each node tracks unsatisfied conditions and the action that led here.[br]
## Forms a linked list via [member parent] for plan reconstruction.
class PlanNode:
	## Conditions still needing satisfaction. Empty = goal reached.
	var unsatisfied: Dictionary[StringName, Variant]
	## Action satisfying some conditions ([code]null[/code] for start node).
	var action: GOAPAction
	## Previous node in search path (toward goal state).
	var parent: PlanNode
	## Accumulated cost from start (g in A*).
	var g_cost: float
	## Heuristic estimate to goal (h in A*).
	var h_cost: float
	## Total estimated cost: [code]g_cost + h_cost[/code].
	var f_cost: float

	func _init(
		u: Dictionary[StringName, Variant],
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

	## Generates unique hash key for this node's unsatisfied conditions.[br]
	## Used by closed set to detect duplicate states.[br][br]
	##
	## Returns MD5 hash string of sorted condition key-value pairs.
	func get_state_key() -> StringName:
		var keys: Array = unsatisfied.keys()
		keys.sort()
		var parts: Array[StringName] = []
		for key in keys:
			parts.append("%s=%s" % [key, str(unsatisfied[key])])
		return "|".join(parts).md5_text()


## Creates optimal action plan for a goal.[br][br]
##
## Uses backward A* search starting from [param goal]'s desired state,
## finding actions whose effects satisfy unsatisfied conditions.[br][br]
##
## [b]Architecture:[/b] Planning uses ONLY the provided state (beliefs),
## never WorldState (truth). Plans are based on what the agent believes,
## which may be incomplete, stale, or incorrect.[br][br]
##
## [param current_state] Current belief state to plan from.[br]
## [param available_actions] Actions available for planning.[br]
## [param goal] Goal to achieve.[br]
## [br]
## Returns actions in execution order, or empty array if no plan exists.
func plan(
	current_state: GOAPState,
	available_actions: Array[GOAPAction],
	goal: GOAPGoal
) -> Array[GOAPAction]:
	var usable_actions := available_actions

	var effect_index := _build_effect_index(usable_actions)
	var goal_conditions: Dictionary[StringName, Variant] = goal.desired_state.duplicate()
	var initial_unsatisfied: Dictionary[StringName, Variant] = current_state.get_unsatisfied_conditions(goal_conditions)

	if initial_unsatisfied.is_empty():
		return []

	var open_list: Array[PlanNode] = []
	var closed_set: Dictionary[StringName, bool] = {}

	var start_h := _calculate_heuristic(initial_unsatisfied, usable_actions)
	var start_node := PlanNode.new(initial_unsatisfied, null, null, 0.0, start_h)
	open_list.append(start_node)

	while open_list.size() > 0:
		var current := _get_lowest_cost_node(open_list)
		open_list.erase(current)

		var state_key := current.get_state_key()

		if closed_set.has(state_key):
			continue

		closed_set[state_key] = true
		if current.unsatisfied.is_empty():
			return _reconstruct_plan(current)

		# Get relevant actions from index instead of iterating all
		var relevant_actions := _get_relevant_actions(current.unsatisfied, effect_index, usable_actions)

		for action in relevant_actions:
			var new_unsatisfied: Dictionary[StringName, Variant] = action.regress_conditions(current.unsatisfied, current_state)
			var new_state_key := _dict_to_key(new_unsatisfied)
			if closed_set.has(new_state_key):
				continue

			var new_g: float = current.g_cost + action.cost
			var new_h: float = _calculate_heuristic(new_unsatisfied, usable_actions)
			var neighbor := PlanNode.new(new_unsatisfied, action, current, new_g, new_h)

			# Check if we already have a better path to this state
			# Replace only if new_g < old_g
			var existing := _find_node_with_key(open_list, new_state_key)
			if existing == null:
				open_list.append(neighbor)
			elif new_g < existing.g_cost:
				open_list.erase(existing)
				open_list.append(neighbor)

	return []


## Calculates admissible heuristic for remaining plan cost.[br][br]
##
## Uses max of minimum costs per condition. Admissible because:[br]
## - Each condition needs at least one action[br]
## - One action may satisfy multiple conditions (use max, not sum)[br][br]
##
## [param unsatisfied] Conditions still needing satisfaction.[br]
## [param actions] Available actions to consider.[br]
## [br]
## Returns heuristic cost estimate (never overestimates).
func _calculate_heuristic(
	unsatisfied: Dictionary[StringName, Variant],
	actions: Array[GOAPAction]
) -> float:
	if unsatisfied.is_empty():
		return 0.0

	var condition_min_costs: Dictionary[StringName, float] = {}
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
		var conditions_satisfied: Array[StringName] = []
		for key in unsatisfied:
			var required_value: Variant = unsatisfied[key]
			if action.effects.has(key) and action.effects[key] == required_value:
				conditions_satisfied.append(key)

		if conditions_satisfied.size() > 1:
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


## Selects node with lowest f_cost from open list.[br][br]
##
## Tie-breaker: prefers higher g_cost (more actions taken = closer to solution).[br][br]
##
## [param nodes] Open list of nodes to search.[br]
## [br]
## Returns node with minimum f_cost.
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


## Generates unique hash key for a conditions dictionary.[br][br]
##
## [param dict] Dictionary of condition key-value pairs.[br]
## [br]
## Returns MD5 hash of sorted key-value pairs.
func _dict_to_key(dict: Dictionary[StringName, Variant]) -> StringName:
	var keys: Array = dict.keys()
	keys.sort()
	var parts: Array[StringName] = []
	for key in keys:
		parts.append("%s=%s" % [key, str(dict[key])])
	return "|".join(parts).md5_text()


## Finds node in open list matching the given state key.[br][br]
##
## [param nodes] List of nodes to search.[br]
## [param state_key] Hash key to match.[br]
## [br]
## Returns matching node or [code]null[/code] if not found.
func _find_node_with_key(nodes: Array[PlanNode], state_key: StringName) -> PlanNode:
	for node in nodes:
		if node.get_state_key() == state_key:
			return node
	return null


## Builds index mapping effect keys to actions that produce them.[br][br]
##
## [param actions] Actions to index.[br]
## [br]
## Returns dictionary mapping effect keys to arrays of actions.
func _build_effect_index(actions: Array[GOAPAction]) -> Dictionary:
	var index: Dictionary = {}  # StringName -> Array[GOAPAction]
	for action in actions:
		for key in action.effects:
			if not index.has(key):
				index[key] = []
			index[key].append(action)
	return index


## Gets actions relevant to unsatisfied conditions using effect index.[br][br]
##
## [param unsatisfied] Conditions needing satisfaction.[br]
## [param effect_index] Prebuilt effect-to-actions mapping.[br]
## [param all_actions] Fallback if condition not in index.[br]
## [br]
## Returns deduplicated array of relevant actions.
func _get_relevant_actions(
	unsatisfied: Dictionary[StringName, Variant],
	effect_index: Dictionary,
	all_actions: Array[GOAPAction]
) -> Array[GOAPAction]:
	var relevant: Dictionary = {}  # Use dict for deduplication

	for key in unsatisfied:
		if effect_index.has(key):
			for action in effect_index[key]:
				relevant[action] = true

	if relevant.is_empty():
		return all_actions

	var result: Array[GOAPAction] = []
	for action in relevant:
		result.append(action)
	return result


## Reconstructs action sequence from completed search.[br][br]
##
## Walks parent chain from solution node. Since backward search was used,
## actions are collected in execution order.[br][br]
##
## [param start_node] Terminal node where [code]unsatisfied.is_empty()[/code].[br]
## [br]
## Returns actions in execution order.
func _reconstruct_plan(start_node: PlanNode) -> Array[GOAPAction]:
	var plan_arr: Array[GOAPAction] = []
	var current: PlanNode = start_node

	while current != null and current.action != null:
		plan_arr.append(current.action)
		current = current.parent

	return plan_arr
