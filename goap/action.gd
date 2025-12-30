@abstract
class_name GOAPAction
extends Resource

## Base class for all GOAP actions. Actions represent things an agent can do.
## Each action has preconditions (requirements), effects (outcomes), and a cost.

## The display name of this action
@export var action_name: String = "Unnamed Action"

## The cost to perform this action. Lower costs are preferred by the planner.
@export var cost: float = 1.0

## Conditions that must be true in the world state before this action can execute.
@export var preconditions: Dictionary[String, Variant] = {}

## Changes this action will make to the world state when executed.
@export var effects: Dictionary[String, Variant] = {}


## Checks if this action's preconditions are satisfied by the given state.
## Used by the planner during plan generation.
## Returns true if all preconditions match the state, false otherwise.
func check_preconditions(state: GOAPState) -> bool:
	return state.matches_conditions(preconditions)


## Applies this action's effects to a state copy.
## Used by the planner to simulate action outcomes during planning.
## Returns a new state with the effects applied.
func apply_effects(state: GOAPState) -> GOAPState:
	var new_state: GOAPState = state.duplicate(true)
	new_state.apply_effects(effects)
	return new_state


## Check if the action can be performed right now.
## This is different from preconditions - use this for runtime checks like
## "is the target in range?" or "do we have the required item in inventory?"
## Returns true if the action can be performed, false otherwise.
@abstract
func can_perform(agent: GOAPAgent) -> bool


## Execute the action. Called every frame while the action is active.
## Returns true when the action is complete, false while it's still running.
@abstract
func perform(agent: GOAPAgent) -> bool


## Virtual method called once when the action starts.
## Override for initialization logic.
func enter(_agent: GOAPAgent) -> void:
	print("Begin '%s' action" % [action_name])


## Virtual method called once when the action ends.
## Override for cleanup logic.
func exit(_agent: GOAPAgent) -> void:
	print("End '%s' action" % [action_name])
