class_name GOAPAgent
extends RigidBody3D

## Main GOAP agent that manages goals, planning, and action execution.
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


func _ready() -> void:
	initialize_blackboard()
	initialize_world_state()
	setup_actions()
	setup_goals()


## Override this method to set the initial blackboard values for your agent.
## This is the agent's personal memory/knowledge.
func initialize_blackboard() -> void:
	pass


## Override this method to set or contribute to the shared world state.
## Only set values that this agent is responsible for initializing.
func initialize_world_state() -> void:
	pass


## Override this method to create and add all actions to the actions array.
## Alternatively, assign actions in the editor inspector.
func setup_actions() -> void:
	pass


## Override this method to create and add all goals to the goals array.
## Alternatively, assign goals in the editor inspector.
func setup_goals() -> void:
	pass


func _process(_delta: float) -> void:
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
		if goal.is_relevant(self) and not goal.is_achieved(world_state):
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
	# Check if goal is already achieved
	if current_goal and current_goal.is_achieved(world_state):
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
