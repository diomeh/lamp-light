## GOAP agent that plans and executes actions to achieve goals.
##
## Core component of the GOAP system. Manages belief state (blackboard),[br]
## selects goals, creates plans, and executes actions.[br][br]
##
## [b]Architecture:[/b][br]
## - [member blackboard]: Agent's beliefs (what it thinks is true)[br]
## - [member actions]: Available actions for planning[br]
## - [member goals]: Pursuable goals, selected by priority[br]
## - Sensors (children): Update blackboard from world state[br]
## - Orchestrator handles IDLE/PLANNING, agent handles PERFORMING[br][br]
##
## [b]State Flow:[/b][br]
## [codeblock]
## IDLE ──(orchestrator.think())──► PLANNING ──► PERFORMING ──► IDLE
##                                                    │
##                                          (agent._physics_process)
## [/codeblock]
## [br]
## [b]Key Principles:[/b][br]
## - Plans use ONLY the blackboard (beliefs), never world state directly[br]
## - Sensors bridge world → blackboard with perception filters[br]
## - Actions execute in the real world[br][br]
##
## See also: [GOAPPlanner], [GOAPAction], [GOAPGoal], [GOAPExecutor], [GOAPOrchestrator]
class_name GOAPAgent
extends Node

## Emitted when a new goal is selected.[br]
## [param goal] The selected goal.
signal goal_selected(goal: GOAPGoal)

## Emitted when a plan is created successfully.[br]
## [param goal] The goal being pursued.[br]
## [param plan] Array of planned actions.
signal plan_created(goal: GOAPGoal, plan: Array[GOAPAction])

## Emitted when planning fails (no valid plan found).[br]
## [param goal] The goal that couldn't be planned.
signal plan_failed(goal: GOAPGoal)

## Emitted when a plan completes successfully.[br]
## [param goal] The achieved goal.
signal plan_completed(goal: GOAPGoal)

## Emitted when a plan is aborted due to action failure.[br]
## [param goal] The goal that was being pursued.[br]
## [param action] The action that failed.
signal plan_aborted(goal: GOAPGoal, action: GOAPAction)

## Available actions for planning.
@export var actions: Array[GOAPAction] = []

## Goals this agent can pursue.[br]
## Selected by priority via [method GOAPGoal.get_priority].
@export var goals: Array[GOAPGoal] = []

## Private memory representing what this agent BELIEVES to be true.[br][br]
##
## [b]Architecture:[/b] Blackboard is the ONLY state used for planning.[br]
## It represents beliefs, which may be incomplete, stale, or incorrect.[br]
## Sensors update the blackboard based on perceived world changes.
var blackboard: GOAPState = GOAPState.new()

## The actor this agent controls (parent node).[br]
## Set automatically in [method _ready].
var actor: Node

## Currently active goal, or [code]null[/code] if idle.
var current_goal: GOAPGoal = null

## Plan executor instance.
var _executor: GOAPExecutor = GOAPExecutor.new()

## Agent state machine states.
enum State {
	IDLE,       ## Waiting for orchestrator to call think()
	PLANNING,   ## Creating plan via GOAPPlanner
	PERFORMING  ## Executing plan actions (self-driven)
}

## Current state machine state.
var _state: State = State.IDLE


## Creates a new GOAPAgent with optional initial configuration.[br][br]
##
## [param initial_blackboard] Initial blackboard state.[br]
## [param initial_actions] Available actions array.[br]
## [param initial_goals] Available goals array.
func _init(
	initial_blackboard: GOAPState = null,
	initial_actions: Array[GOAPAction] = [],
	initial_goals: Array[GOAPGoal] = []
) -> void:
	if initial_blackboard:
		blackboard = initial_blackboard
	if not initial_actions.is_empty():
		actions = initial_actions
	if not initial_goals.is_empty():
		goals = initial_goals


func _ready() -> void:
	actor = get_parent()

	_executor.plan_completed.connect(_on_executor_plan_completed)
	_executor.plan_failed.connect(_on_executor_plan_failed)

	GOAPOrchestrator.register_agent(self)


func _exit_tree() -> void:
	GOAPOrchestrator.unregister_agent(self)


func _physics_process(delta: float) -> void:
	# Only self-drive during PERFORMING state
	# IDLE and PLANNING are handled by GOAPOrchestrator
	if _state == State.PERFORMING:
		_process_performing(delta)


## Returns true if agent needs orchestrator to call think().[br][br]
##
## Used by [GOAPOrchestrator] to determine scheduling.
func needs_thinking() -> bool:
	return _state == State.IDLE


## Executes one think cycle (goal selection + planning).[br][br]
##
## Called by [GOAPOrchestrator] when agent is due for thinking.[br]
## Handles IDLE → PLANNING → PERFORMING transition.
func think() -> void:
	if _state == State.IDLE:
		_process_idle()

	if _state == State.PLANNING:
		_process_planning()


## Returns priority for orchestrator scheduling.[br][br]
##
## Override for LOD-based prioritization (e.g., distance to player).[br]
## Higher values = higher priority.
func get_think_priority() -> float:
	return 1.0


## Returns current agent state.
func get_state() -> State:
	return _state


## Returns current action being executed, or null.
func get_current_action() -> GOAPAction:
	return _executor.get_current_action()


## Returns true if agent is currently executing a plan.
func is_performing() -> bool:
	return _state == State.PERFORMING


## Forces agent to abort current plan and return to idle.[br][br]
##
## Safe to call in any state.
func abort() -> void:
	if _state == State.PERFORMING:
		_executor.abort(self)

	if current_goal:
		plan_aborted.emit(current_goal, _executor.get_current_action())

	_reset_to_idle()


## Process IDLE state: select highest priority goal.
func _process_idle() -> void:
	var goal := _select_goal()

	if goal:
		current_goal = goal
		goal_selected.emit(goal)
		_state = State.PLANNING


## Process PLANNING state: create plan for current goal.
func _process_planning() -> void:
	if not current_goal:
		_state = State.IDLE
		return

	var plan := GOAPPlanner.plan(self)

	if plan.is_empty():
		plan_failed.emit(current_goal)
		_reset_to_idle()
	else:
		plan_created.emit(current_goal, plan)
		_executor.start(plan)
		_state = State.PERFORMING


## Process PERFORMING state: tick executor.
func _process_performing(delta: float) -> void:
	# Early goal completion check (goal achieved by external means)
	if current_goal and current_goal.is_achieved(blackboard.to_ref()):
		_executor.abort(self)
		_complete_goal()
		return

	_executor.tick(self, delta)


## Selects highest priority relevant, unachieved goal.[br][br]
##
## Returns selected goal or null if none available.
func _select_goal() -> GOAPGoal:
	var best_goal: GOAPGoal = null
	var best_priority: float = -INF
	var state_ref := blackboard.to_ref()

	for goal in goals:
		if not goal.is_relevant(state_ref):
			continue

		if goal.is_achieved(state_ref):
			continue

		var priority := goal.get_priority(state_ref)
		if priority > best_priority:
			best_priority = priority
			best_goal = goal

	return best_goal


## Called when executor completes plan successfully.
func _on_executor_plan_completed() -> void:
	_complete_goal()


## Called when executor fails due to action failure.
func _on_executor_plan_failed(action: GOAPAction) -> void:
	var failed_goal := current_goal
	_reset_to_idle()
	plan_aborted.emit(failed_goal, action)


## Completes current goal and returns to idle.
func _complete_goal() -> void:
	var completed_goal := current_goal

	if completed_goal:
		completed_goal.after_plan_complete(self)

	_reset_to_idle()

	if completed_goal:
		plan_completed.emit(completed_goal)


## Resets agent to idle state.
func _reset_to_idle() -> void:
	current_goal = null
	_state = State.IDLE
