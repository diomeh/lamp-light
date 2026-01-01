## Abstract base class for all GOAP actions.
##
## Actions represent discrete behaviors an agent can perform. Each action defines:[br]
## - [member preconditions]: World state requirements for planning[br]
## - [member effects]: State changes when executed[br]
## - [member cost]: Used by planner to find optimal plans[br]
##
## [br]
## [b]Lifecycle:[/b]
## [codeblock]
## can_perform() -> enter() -> perform() [loop] -> exit()
## [/codeblock]
## [br]
##
## [b]Example implementation:[/b]
##
## [codeblock]
## class_name MyAction
## extends GOAPAction
##
## func _init() -> void:
##     action_name = "My Action"
##     cost = 1.0
##     preconditions = {"has_item": true}
##     effects = {"item_used": true}
##
## func can_perform(agent: GOAPAgent) -> bool:
##     return agent.actor.has_item()
##
## func perform(agent: GOAPAgent) -> bool:
##     return agent.actor.use_item()
## [/codeblock]
##
## [br]
##
## See also:[br]
## [GOAPAgent][br]
## [GOAPPlanner][br]
@abstract
class_name GOAPAction
extends Resource

## Display name.
@export var action_name: String = "Unnamed Action"

## Planning cost. Lower values are preferred by the planner.[br]
## Must be non-negative for A* admissibility.
@export var cost: float = 1.0

## Conditions required in world state for this action to be considered during planning.
## [br][br]
## [b]Note:[/b] These are checked symbolically by the planner, not at runtime.
## Use [method can_perform] for runtime validation.
@export var preconditions: Dictionary[String, Variant] = {}

## State changes applied when this action completes.[br]
## Used by the planner to simulate action outcomes during backward search.
@export var effects: Dictionary[String, Variant] = {}


## Checks if this action's preconditions are satisfied by the given state.[br][br]
##
## [param state] The world state to check against.[br]
## Returns [code]true[/code] if all preconditions match, [code]false[/code] otherwise.
func check_preconditions(state: GOAPState) -> bool:
	return state.matches_conditions(preconditions)


## Applies this action's effects to a copy of the given state.[br]
## [br]
## [param state] The state to apply effects to.[br]
## Returns a new [GOAPState] with effects applied.
func apply_effects(state: GOAPState) -> GOAPState:
	var new_state: GOAPState = state.duplicate(true)
	new_state.apply_effects(effects)
	return new_state


## Runtime check if action can be performed now.[br][br]
##
## Unlike [member preconditions] which are checked symbolically during planning,
## this method validates real-world conditions like range, inventory, cooldowns, etc.[br][br]
##
## [param agent] The agent attempting to perform this action.[br]
## Returns [code]true[/code] if action can execute, [code]false[/code] otherwise.
@abstract
func can_perform(agent: GOAPAgent) -> bool


## Executes the action logic. Called every physics frame while active.[br][br]
##
## [param agent] The agent performing this action.[br]
## Returns [code]true[/code] when complete, [code]false[/code] while still running.
@abstract
func perform(agent: GOAPAgent) -> bool


## Called once when the action starts executing.[br]
## Override for initialization logic (e.g., starting animations, setting up state).[br][br]
##
## [param agent] The agent starting this action.
@warning_ignore("unused_parameter")
func enter(agent: GOAPAgent) -> void:
	print("Begin '%s' action" % [action_name])


## Called once when the action finishes or is interrupted.[br]
## Override for cleanup logic (e.g., stopping animations, resetting state).[br][br]
##
## [param agent] The agent ending this action.
@warning_ignore("unused_parameter")
func exit(agent: GOAPAgent) -> void:
	print("End '%s' action" % [action_name])


## Checks if this action's effects satisfy at least one unsatisfied condition.[br]
## Used by [GOAPPlanner] to filter relevant actions during backward search.[br][br]
##
## [param unsatisfied] Dictionary of conditions that need to be satisfied.[br]
## Returns [code]true[/code] if any effect matches an unsatisfied condition.
func satisfies_any(unsatisfied: Dictionary[String, Variant]) -> bool:
	for key in effects:
		if unsatisfied.has(key) and effects[key] == unsatisfied[key]:
			return true
	return false


## Applies symbolic backward regression for planning.[br][br]
##
## This is the core operation for backward A* search:[br]
## - Removes conditions satisfied by this action's [member effects][br]
## - Adds all [member preconditions] as new conditions to satisfy[br]
## - Optionally filters out conditions already satisfied by current state[br][br]
##
## [param unsatisfied] Current unsatisfied conditions.[br]
## [param state] Optional world state to filter already-satisfied preconditions.[br]
## Returns a new dictionary of unsatisfied conditions after regression.
func regress_conditions(
	unsatisfied: Dictionary[String, Variant],
	state: GOAPState = null
) -> Dictionary[String, Variant]:
	var new_unsatisfied: Dictionary[String, Variant] = unsatisfied.duplicate()

	# Remove conditions that this action's effects will satisfy
	for key in effects:
		if new_unsatisfied.has(key) and effects[key] == new_unsatisfied[key]:
			new_unsatisfied.erase(key)

	# Preconditions must now be satisfied
	new_unsatisfied.merge(preconditions, true)

	# Remove conditions already satisfied by state
	# An action may add preconditions that are already true in the world
	if state:
		new_unsatisfied = state.get_unsatisfied_conditions(new_unsatisfied)

	return new_unsatisfied
