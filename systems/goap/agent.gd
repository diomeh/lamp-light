## Main GOAP agent component implementing the sense-think-act loop.
##
## Manages goal selection, planning via [GOAPPlanner], and action execution.[br]
## Each agent has:[br]
## - [member world_state]: Shared global facts (e.g., light positions)[br]
## - [member blackboard]: Private memory (e.g., current target, health)[br][br]
##
## [b]State Machine:[/b]
## [codeblock]
## IDLE -> PLANNING -> PERFORMING -> IDLE
##   ^         |            |          |
##   |_________|____________|__________|
## [/codeblock][br]
##
## [b]Usage:[/b] Add as child of an actor node. The parent becomes [member actor].[br][br]
##
## See also:[br]
## [GOAPAction][br]
## [GOAPGoal][br]
## [GOAPPlanner][br]
class_name GOAPAgent
extends Node

## Available actions this agent can perform.[br]
## Filtered by [method GOAPAction.can_perform] before planning.
@export var actions: Array[GOAPAction] = []

## Goals this agent can pursue, selected by priority via [method GOAPGoal.get_priority].
@export var goals: Array[GOAPGoal] = []

## Private memory representing what this agent BELIEVES to be true.[br]
## [br][br]
## [b]Architecture:[/b] Blackboard is the ONLY state used for planning.[br]
## It represents beliefs, which may be incomplete, stale, or incorrect.[br]
## Sensors update the Blackboard based on perceived WorldState changes.[br]
## [br][br]
## [b]Examples:[/b] [code]target_position[/code], [code]health[/code], [code]move_speed[/code],
## [code]visible_enemies[/code], [code]light_positions[/code]
var blackboard: GOAPState = GOAPState.new()

## The actor this agent controls (parent node).[br]
## Set automatically in [method _ready].
var actor: Actor

## Currently active goal, or [code]null[/code] if idle.
var current_goal: GOAPGoal = null

## Sequence of actions to achieve [member current_goal].
var current_plan: Array[GOAPAction] = []

## Action currently executing, or [code]null[/code] if between actions.
var current_action: GOAPAction = null

## Index into [member current_plan] for current action.
var current_action_index: int = 0

## Agent state machine states.
enum State {
	IDLE, ## Selecting next goal
	PLANNING, ## Creating plan via [GOAPPlanner]
	PERFORMING ## Executing plan actions
}

## Current state machine state.
var agent_state: State = State.IDLE

## Creates a new GOAPAgent with optional initial configuration.[br][br]
##
## [param bb] Initial blackboard state.[br]
## [param a] Available actions array.[br]
## [param g] Available goals array.[br]
func _init(
	bb: GOAPState = null,
	a: Array[GOAPAction]=[],
	g: Array[GOAPGoal]=[]
) -> void:
	if bb: blackboard = bb
	if not a.is_empty(): actions = a
	if not g.is_empty(): goals = g


func _ready() -> void:
	# Get reference to the actor we're controlling
	actor = get_parent() as Actor

	assert(actor != null, "GOAPAgent must be a child of an actor node.")


func _physics_process(delta: float) -> void:
	if not actor:
		return

	match agent_state:
		State.IDLE:
			_select_goal()
			if current_goal:
				agent_state = State.PLANNING

		State.PLANNING:
			_create_plan()

		State.PERFORMING:
			_execute_plan(delta)


## Selects highest priority relevant goal that isn't achieved.[br][br]
##
## Iterates [member goals], filtering by [method GOAPGoal.is_relevant] and
## [method GOAPGoal.is_achieved].[br]
## Sets [member current_goal] to winner or [code]null[/code].[br][br]
##
## [b]Architecture:[/b] Goals are evaluated against the Blackboard (beliefs),
## not WorldState (truth). Agents pursue goals based on what they believe.
func _select_goal() -> void:
	current_goal = null
	var highest_priority: float = - INF

	for goal in goals:
		if not goal.is_relevant(self):
			continue

		# Check if goal is already achieved according to agent's beliefs
		if goal.is_achieved(blackboard):
			continue

		var priority: float = goal.get_priority(self)
		if priority > highest_priority:
			highest_priority = priority
			current_goal = goal


## Creates action plan via [GOAPPlanner] for [member current_goal].[br][br]
##
## Transitions to [enum State.PERFORMING] on success, [enum State.IDLE] on failure.
func _create_plan() -> void:
	if current_goal == null:
		agent_state = State.IDLE
		return

	current_plan = GOAPPlanner.plan(self)

	if current_plan.is_empty():
		print("No plan found for goal: ", current_goal.goal_name)
		current_goal = null
		agent_state = State.IDLE
	else:
		print("Plan created with ", current_plan.size(), " actions")
		current_action_index = 0
		current_action = null
		agent_state = State.PERFORMING


## Executes [member current_plan] sequentially until goal is achieved or plan exhausted.[br][br]
##
## Calls [method GOAPAction.enter], [method GOAPAction.perform], and
## [method GOAPAction.exit] for each action.[br][br]
##
## [b]Architecture:[/b] Goal achievement is checked against Blackboard (beliefs).
## If reality differs from beliefs, sensors will update Blackboard and trigger replanning.
func _execute_plan(delta: float) -> void:
	# Check if goal is already achieved according to agent's beliefs
	if current_goal and current_goal.is_achieved(blackboard):
		_finish_plan()
		return

	# Start next action if needed
	if current_action == null:
		if current_action_index >= current_plan.size():
			_finish_plan()
			return

		current_action = current_plan[current_action_index]
		current_action.enter(self)

	# Perform current action
	if current_action.perform(self, delta):
		current_action.exit(self)
		current_action = null
		current_action_index += 1


## Cleans up plan execution and transitions to [enum State.IDLE].[br][br]
##
## Calls [method GOAPAction.exit] on [member current_action] if active.
func _finish_plan() -> void:
	if current_action:
		current_action.exit(self)

	print("Plan complete for goal: ", current_goal.goal_name if current_goal else "None")
	current_goal.after_plan_complete(self)
	current_plan.clear()
	current_action = null
	current_goal = null
	agent_state = State.IDLE
