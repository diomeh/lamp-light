## Base class for GOAP actions that agents can perform.
##
## Actions represent atomic behaviors with symbolic preconditions and effects.[br]
## Used by [GOAPPlanner] to construct plans that achieve goals.[br][br]
##
## [b]Architecture:[/b][br]
## - [member preconditions]: Conditions that must be true to use this action in a plan[br]
## - [member effects]: State changes this action produces (symbolic)[br]
## - [member cost]: Planning cost (lower = preferred)[br]
## - Runtime execution via [method perform][br][br]
##
## [b]Usage:[/b]
## [codeblock]
## extends GOAPAction
##
## func _init() -> void:
##     action_name = "MoveTo"
##     cost = 1.0
##     preconditions = {"target_position": Vector3.ZERO}
##     effects = {"at_target": true}
##
## func perform(agent: GOAPAgent, delta: float) -> ExecResult:
##     # Execute movement logic
##     if reached_target():
##         return ExecResult.SUCCESS
##     return ExecResult.RUNNING
## [/codeblock]
## [br]
## See also: [GOAPAgent], [GOAPPlanner], [GOAPGoal]
class_name GOAPAction
extends Resource

## Display name for this action.
@export var action_name: StringName = "Unnamed Action"

## Planning cost. Lower values are preferred by the planner.
@export var cost: float = 1.0

## Symbolic conditions required to use this action in a plan.[br]
## Example: [code]{"has_axe": true, "tree_nearby": true}[/code]
@export var preconditions: Dictionary[StringName, Variant] = {}

## Symbolic state changes produced by this action.[br]
## Example: [code]{"has_wood": true, "tree_nearby": false}[/code]
@export var effects: Dictionary[StringName, Variant] = {}

## Action execution result states.
enum ExecResult {
	SUCCESS, ## Action completed successfully
	FAILURE, ## Action failed and cannot continue
	RUNNING, ## Action is still executing
}


## Retrieves the planning cost of this action.[br][br]
##
## [param state] Current agent state (for dynamic cost calculation).[br]
## [br]
## Returns cost value.
@warning_ignore("unused_parameter")
func get_cost(state: Dictionary[StringName, Variant]) -> float:
	return cost


## Retrieves preconditions for this action.[br][br]
##
## [param state] Current agent state (for dynamic preconditions).[br]
## [br]
## Returns dictionary of preconditions.
@warning_ignore("unused_parameter")
func get_preconditions(state: Dictionary[StringName, Variant]) -> Dictionary[StringName, Variant]:
	return preconditions


## Retrieves effects for this action.[br][br]
##
## [param state] Current agent state (for dynamic effects).[br]
## [br]
## Returns dictionary of effects.
@warning_ignore("unused_parameter")
func get_effects(state: Dictionary[StringName, Variant]) -> Dictionary[StringName, Variant]:
	return effects


## Checks if runtime preconditions are satisfied by the given state.[br][br]
##
## Override to implement runtime validation (e.g., path exists, target in range).[br]
## This is separate from symbolic [member preconditions] used in planning.[br][br]
##
## [param state] State to check against.[br]
## [br]
## Returns [code]true[/code] if all [member preconditions] are met.
func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	for key in preconditions:
		if not state.has(key) or state[key] != preconditions[key]:
			return false
	return true


## Applies action effects to a state (creates new state).[br][br]
##
## [param state] Original state.[br]
## [br]
## Returns new [GOAPState] with [member effects] applied.
func apply_effects(state: GOAPState) -> GOAPState:
	var new_state: GOAPState = state.duplicate()
	new_state.apply_effects(effects)
	return new_state


## Executes action logic each frame.[br][br]
##
## Override to implement action behavior. Return [constant ExecResult.RUNNING] while[br]
## working, [constant ExecResult.SUCCESS] when done, or [constant ExecResult.FAILURE] if failed.[br][br]
##
## [param agent] Agent performing this action.[br]
## [param delta] Time since last frame in seconds.[br]
## [br]
## Returns execution status.
@warning_ignore("unused_parameter")
func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	return ExecResult.SUCCESS


## Called once when action starts executing.[br][br]
##
## Override for initialization (start animations, reserve resources, etc.).[br][br]
##
## [param agent] Agent starting this action.
@warning_ignore("unused_parameter")
func enter(agent: GOAPAgent) -> void:
	pass


## Called once when action finishes or is interrupted.[br][br]
##
## Override for cleanup (stop animations, release resources, etc.).[br][br]
##
## [param agent] Agent ending this action.
@warning_ignore("unused_parameter")
func exit(agent: GOAPAgent) -> void:
	pass


## Checks if this action satisfies any of the given unsatisfied conditions.[br][br]
##
## Used by [GOAPPlanner] during backward search.[br][br]
##
## [param unsatisfied] Conditions needing satisfaction.[br]
## [br]
## Returns [code]true[/code] if any [member effects] match unsatisfied conditions.
func satisfies_any(unsatisfied: Dictionary[StringName, Variant]) -> bool:
	for key in effects:
		if unsatisfied.has(key) and effects[key] == unsatisfied[key]:
			return true
	return false


## Performs backward state regression for planning.[br][br]
##
## Used by [GOAPPlanner] to determine new unsatisfied conditions when[br]
## this action is added to a plan.[br][br]
##
## [param unsatisfied] Current unsatisfied conditions.[br]
## [param state] Current believed state (for filtering already-satisfied conditions).[br]
## [br]
## Returns new unsatisfied conditions after regressing through this action.
func regress_conditions(
	unsatisfied: Dictionary[StringName, Variant],
	state: GOAPState = null
) -> Dictionary[StringName, Variant]:
	var new_unsatisfied: Dictionary[StringName, Variant] = unsatisfied.duplicate()

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
