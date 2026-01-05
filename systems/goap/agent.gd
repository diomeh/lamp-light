## GOAP agent that plans and executes actions to achieve goals.
##
## Core component of the GOAP system. Manages belief state (blackboard),[br]
## selects goals, creates plans, and executes actions.[br][br]
##
## [b]Architecture:[/b][br]
## - [member blackboard]: Agent's beliefs (what it thinks is true)[br]
## - [member actions]: Available actions for planning[br]
## - [member goals]: Pursuable goals, selected by priority[br]
## - Sensors (children): Update blackboard from WorldState[br]
## - Three-state FSM: IDLE → PLANNING → PERFORMING → IDLE[br][br]
##
## [b]Key Principles:[/b][br]
## - Plans use ONLY the blackboard (beliefs), never WorldState (truth)[br]
## - Sensors bridge WorldState → Blackboard with perception filters[br]
## - Actions execute in the real world[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## # Agent setup in scene tree:
## Actor (parent)
## └─ GOAPAgent
##    ├─ ProximitySensor (child)
##    └─ VisionSensor (child)
##
## # Configure in code:
## agent.actions = [move_action, gather_action]
## agent.goals = [survive_goal, collect_goal]
## agent.blackboard.set_value("health", 100)
## [/codeblock]
## [br]
## See also: [GOAPPlanner], [GOAPAction], [GOAPGoal], [GOAPSensor]
class_name GOAPAgent
extends Node

## Available actions for planning.[br]
## Filtered by [method GOAPAction.can_perform] before planning.
@export var actions: Array[GOAPAction] = []

## Goals this agent can pursue.[br]
## Selected by priority via [method GOAPGoal.get_priority].
@export var goals: Array[GOAPGoal] = []

## Private memory representing what this agent BELIEVES to be true.[br][br]
##
## [b]Architecture:[/b] Blackboard is the ONLY state used for planning.[br]
## It represents beliefs, which may be incomplete, stale, or incorrect.[br]
## Sensors update the Blackboard based on perceived [WorldState] changes.[br][br]
##
## [b]Examples:[/b] [code]{"target_position": Vector3.ZERO, "health": 100,
## "visible_enemies": [1, 2, 3]}[/code]
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


## Selects highest priority goal from available goals.[br][br]
##
## Called in IDLE state. Filters by [method GOAPGoal.is_relevant] and[br]
## [method GOAPGoal.is_achieved], then selects highest [method GOAPGoal.get_priority].
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


## Creates action plan to achieve [member current_goal].[br][br]
##
## Called in PLANNING state. Uses [GOAPPlanner] to find action sequence.[br]
## Transitions to PERFORMING if plan found, IDLE if planning fails.
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


## Executes current plan action by action.[br][br]
##
## Called in PERFORMING state. Manages action lifecycle:[br]
## [method GOAPAction.enter] → [method GOAPAction.perform] → [method GOAPAction.exit].[br]
## Advances through plan until goal achieved or plan completes.[br][br]
##
## [param delta] Time since last frame in seconds.
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
	if current_action.perform(self, delta) == GOAPAction.PerformResult.SUCCESS:
		current_action.exit(self)
		current_action = null
		current_action_index += 1


## Completes current plan and returns to IDLE state.[br][br]
##
## Calls [method GOAPGoal.after_plan_complete] and cleans up plan state.
func _finish_plan() -> void:
	if current_action:
		current_action.exit(self)

	print("Plan complete for goal: ", current_goal.goal_name if current_goal else "None")
	current_goal.after_plan_complete(self)
	current_plan.clear()
	current_action = null
	current_goal = null
	agent_state = State.IDLE
