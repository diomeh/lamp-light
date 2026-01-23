## Base class for GOAP actions that agents can perform.
##
## Actions represent atomic behaviors with symbolic preconditions and effects.[br]
## Used by [GOAPPlanner] to construct plans that achieve goals.[br][br]
##
## [b]Architecture:[/b][br]
## - [member preconditions]: [b]Symbolic[/b] conditions for planning (e.g., [code]{"has_axe": true}[/code])[br]
## - [member effects]: [b]Symbolic[/b] state changes (e.g., [code]{"has_wood": true}[/code])[br]
## - [member cost]: Planning cost (lower values preferred by planner)[br]
## - [method can_execute]: [b]Runtime[/b] validation (e.g., distance checks, pathfinding)[br]
## - [method execute]: Frame-by-frame execution logic[br][br]
##
## [b]Action Author Contract:[/b][br][br]
##
## [b]1. Symbolic Planning ([member preconditions] / [member effects]):[/b][br]
## These are used ONLY during planning to find valid action sequences.[br]
## They represent abstract logical requirements, not runtime checks.[br]
## Example: [code]{"near_tree": true}[/code] means logically positioned, not actual distance.[br][br]
##
## [b]2. Runtime Validation ([method can_execute]):[/b][br]
## Override this to check if action can actually execute RIGHT NOW.[br]
## Called by executor before [method enter]. Should be fast (no pathfinding).[br]
## Example: Check if target still exists, agent has resources, etc.[br]
## Returns [code]false[/code] to fail action immediately without entering.[br][br]
##
## [b]3. Action Lifecycle:[/b][br]
## - [method enter]: One-time setup (start animations, reserve resources)[br]
## - [method execute]: Called every frame until returns SUCCESS/FAILURE[br]
## - [method exit]: Cleanup (stop animations, release resources)[br][br]
##
## [b]4. Blackboard Updates:[/b][br]
## Actions MUST update [code]agent.blackboard[/code] during [method execute].[br]
## Planner plans based on [member effects], but execution must apply real changes.[br]
## Example: [code]agent.blackboard.set_value("has_wood", true)[/code][br][br]
##
## [b]Usage Example:[/b]
## [codeblock]
## extends GOAPAction
##
## func _init() -> void:
##     action_name = "ChopTree"
##     cost = 2.0
##     # Symbolic: planner uses these to find action sequences
##     preconditions = {"has_axe": true, "near_tree": true}
##     effects = {"has_wood": true, "near_tree": false}
##
## func can_execute(state: Dictionary[StringName, Variant]) -> bool:
##     # Runtime: can we actually do this RIGHT NOW?
##     return state.get("axe_durability", 0) > 0
##
## func enter(agent: GOAPAgent) -> void:
##     # Start chopping animation
##     agent.actor.play_animation("chop")
##
## func execute(agent: GOAPAgent, delta: float) -> ExecResult:
##     # Simulate chopping over time
##     _chop_progress += delta
##     if _chop_progress >= 3.0:
##         # Update blackboard to reflect real world change
##         agent.blackboard.set_value("has_wood", true)
##         agent.blackboard.set_value("near_tree", false)
##         return ExecResult.SUCCESS
##     return ExecResult.RUNNING
##
## func exit(agent: GOAPAgent) -> void:
##     # Stop animation
##     agent.actor.stop_animation()
## [/codeblock]
## [br]
## See also: [GOAPAgent], [GOAPPlanner], [GOAPGoal]
class_name GOAPAction
extends Resource

## Display name for this action.
@export var action_name: StringName = "Unnamed Action"

## Planning cost. Lower values are preferred by the planner.
@export var cost: float = 1.0

## [b]Symbolic[/b] conditions required for planning.[br]
## Used by planner to determine if action is usable in a plan.[br]
## These are LOGICAL requirements, not runtime checks.[br]
## Example: [code]{"has_axe": true, "near_tree": true}[/code]
@export var preconditions: Dictionary[StringName, Variant] = {}

## [b]Symbolic[/b] state changes for planning.[br]
## Used by planner to determine what this action achieves.[br]
## Your [method execute] must apply these changes to [code]agent.blackboard[/code].[br]
## Example: [code]{"has_wood": true, "near_tree": false}[/code]
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


## [b]Runtime validation:[/b] Can this action execute RIGHT NOW?[br][br]
##
## Override to check actual runtime conditions:[br]
## - Does target still exist?[br]
## - Are resources still available?[br]
## - Is path still valid?[br]
## - Any other real-world checks[br][br]
##
## This is separate from symbolic [member preconditions] (used in planning).[br]
## Called by executor before [method enter]. Should be fast.[br][br]
##
## [param state] Current agent state to check against.[br]
## [br]
## Returns [code]true[/code] if action can execute, [code]false[/code] to fail immediately.
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
## Override to implement action behavior:[br]
## - Return [constant ExecResult.RUNNING] while working[br]
## - Return [constant ExecResult.SUCCESS] when done[br]
## - Return [constant ExecResult.FAILURE] if failed[br][br]
##
## [b]IMPORTANT:[/b] You MUST update [code]agent.blackboard[/code] when action succeeds.[br]
## Apply the changes described in [member effects] to the blackboard.[br]
## Example: [code]agent.blackboard.set_value("has_wood", true)[/code][br][br]
##
## [param agent] Agent performing this action (access via [code]agent.blackboard[/code], [code]agent.actor[/code]).[br]
## [param delta] Time since last frame in seconds.[br]
## [br]
## Returns execution status.
@warning_ignore("unused_parameter")
func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	return ExecResult.SUCCESS


## Called once when action starts executing.[br][br]
##
## Override for one-time initialization:[br]
## - Start animations[br]
## - Reserve resources[br]
## - Initialize internal state[br]
## - Store references[br][br]
##
## [param agent] Agent starting this action.
@warning_ignore("unused_parameter")
func enter(agent: GOAPAgent) -> void:
	pass


## Called once when action finishes or is interrupted.[br][br]
##
## Override for cleanup:[br]
## - Stop animations[br]
## - Release resources[br]
## - Clear internal state[br][br]
##
## Called regardless of success or failure, always clean up here.[br][br]
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
