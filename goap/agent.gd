class_name GOAPAgent
extends Node

## Main GOAP agent component.
## Is in charge of managing goals, planning, and action execution.
## This is the core controller that runs the sense-think-act loop.
## The agent has a personal blackboard for private memory and accesses
## a shared world state for global information.

## Array of all available actions this agent can perform.
@export var actions: Array[GOAPAction] = []

## Array of all goals this agent can pursue.
@export var goals: Array[GOAPGoal] = []

## Reference to the shared world state.
## This represents objective facts about the game world that all agents can access.
@export var world_state: GOAPState

## The agent's personal blackboard/memory.
## Stores private information like health, current target, timers, etc.
var blackboard: GOAPState = GOAPState.new()

## Reference to the entity this component controls (parent node).
var entity: Node3D

## The currently active goal being pursued, or null if no goal is active
var current_goal: GOAPGoal = null

## The sequence of actions planned to achieve the current goal
var current_plan: Array[GOAPAction] = []

## The action currently being executed, or null if between actions
var current_action: GOAPAction = null

## Index of the current action in the plan
var current_action_index: int = 0

## Agent state machine states
enum State {
	IDLE,        ## No active goal, selecting next goal
	PLANNING,    ## Creating a plan to achieve the current goal
	PERFORMING   ## Executing the current plan
}

## Current state of the agent's state machine
var agent_state: State = State.IDLE

## Creates a new GOAPAgent component, can recieve 4 parameters treated as references.
## wd; world state
## bb: blackboard
## a: actions
## g: goals
func _init(
	wd: GOAPState = null,
	bb: GOAPState = null,
	a: Array[GOAPAction] = [],
	g: Array[GOAPGoal] = []
) -> void:
	if wd: world_state = wd
	if bb: blackboard = bb
	if not a.is_empty(): actions = a
	if not g.is_empty(): goals = g


func _ready() -> void:
	# Get reference to the entity we're controlling
	entity = get_parent()

	if not entity:
		push_error("GOAPAgent must be a child of an entity node!")
		return

	if not world_state:
		world_state = GOAPState.new()


func _physics_process(_delta: float) -> void:
	if not entity:
		return

	match agent_state:
		State.IDLE:
			_select_goal()
			if current_goal:
				agent_state = State.PLANNING

		State.PLANNING:
			_create_plan()

		State.PERFORMING:
			_execute_plan()


## Selects the highest priority relevant goal that hasn't been achieved.
## Sets current_goal to the selected goal, or null if no goals are available.
func _select_goal() -> void:
	current_goal = null
	var highest_priority: float = -INF

	for goal in goals:
		if not goal.is_relevant(self):
			continue

		var planning_state := get_full_state()
		if goal.is_achieved(planning_state):
			continue

		var priority: float = goal.get_priority(self)
		if priority > highest_priority:
			highest_priority = priority
			current_goal = goal


## Creates a plan to achieve the current goal using the planner.
## Transitions to PERFORMING if plan is found, or back to IDLE if planning fails.
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


## Executes the current plan action by action until complete or goal is achieved.
func _execute_plan() -> void:
	var planning_state := get_full_state()

	# Check if goal is already achieved
	if current_goal and current_goal.is_achieved(planning_state):
		_finish_plan()
		return

	# Start next action if needed
	if current_action == null:
		if current_action_index >= current_plan.size():
			_finish_plan()
			return

		current_action = current_plan[current_action_index]
		current_action.enter(self)
		print("Starting action: ", current_action.action_name)

	# Perform current action
	if current_action.perform(self):
		print("Completed action: ", current_action.action_name)
		current_action.exit(self)
		current_action = null
		current_action_index += 1


## Cleans up after plan completion and transitions back to IDLE state.
func _finish_plan() -> void:
	if current_action:
		current_action.exit(self)

	print("Plan complete for goal: ", current_goal.goal_name if current_goal else "None")
	current_plan.clear()
	current_action = null
	current_goal = null
	agent_state = State.IDLE


## Merges world state and blackboard into a single source of knowledge for this agent.
## Returns a new state.
func get_full_state() -> GOAPState:
	return GOAPState.merge(world_state, blackboard)
