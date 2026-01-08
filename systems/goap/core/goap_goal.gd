## Base class for GOAP goals that agents can pursue.
##
## Goals represent desired states that drive plan creation.[br]
## The [GOAPPlanner] works backward from [member desired_state] to find action sequences.[br][br]
##
## [b]Architecture:[/b][br]
## - [member desired_state]: Symbolic conditions defining goal achievement[br]
## - [member priority]: Base priority (override [method get_priority] for dynamic values)[br]
## - Goals are selected by highest priority among relevant, unachieved goals[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## extends GOAPGoal
##
## func _init() -> void:
##     goal_name = "Survive"
##     priority = 10.0
##     desired_state = {"health": 100}
##
## func get_priority(agent: GOAPAgent) -> float:
##     var hp = agent.blackboard.get_value("health", 100)
##     return priority * (100.0 - hp) / 100.0  # Higher when hurt
## [/codeblock]
## [br]
## See also: [GOAPAgent], [GOAPPlanner], [GOAPAction]
class_name GOAPGoal
extends Resource

## Display name for this goal.
@export var goal_name: StringName = "Unnamed Goal"

## Base priority value. Higher values are selected first.[br]
## Override [method get_priority] for dynamic priority calculation.
@export var priority: float = 1.0

## Conditions that must be true for this goal to be satisfied.[br]
## The [GOAPPlanner] works backward from these conditions.[br]
## Example: [code]{"has_food": true, "hunger": 0}[/code]
@export var desired_state: Dictionary[StringName, Variant] = {}


## Checks if goal is achieved in the given state.[br][br]
##
## [param state] State to check desired state against.[br]
## [br]
## Returns [code]true[/code] if all [member desired_state] conditions are satisfied.
func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	for key in desired_state.keys():
		if not state.has(key) or state.get(key) != desired_state[key]:
			return false
	return true


## Runtime retrieval of desired state. Override for dynamic goals.[br][br]
##
## [param state] Current agent state.[br][br]
## Returns dictionary of desired conditions.
@warning_ignore("unused_parameter")
func get_desired_state(state: Dictionary[StringName, Variant]) -> Dictionary[StringName, Variant]:
	return desired_state


## Determines if this goal is currently relevant.[br][br]
##
## Override to implement contextual filtering (e.g., only pursue "Eat" if hungry).[br]
## Irrelevant goals are skipped during goal selection.[br][br]
##
## [param state] Current agent state.[br][br]
##
## Returns [code]true[/code] if goal should be considered.
@warning_ignore("unused_parameter")
func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	return true


## Calculates dynamic priority for this goal.[br][br]
##
## Override to implement context-sensitive priority (e.g., health goals become[br]
## more urgent when injured). Base implementation returns [member priority].[br][br]
##
## [param state] Current agent state to evaluate priority against.[br][br]
##
## Returns priority value (higher = more important).
@warning_ignore("unused_parameter")
func get_priority(state: Dictionary[StringName, Variant]) -> float:
	return priority


## Called when plan to achieve this goal completes.[br][br]
##
## Override for post-goal logic (cooldowns, state cleanup, etc.).[br][br]
##
## [param agent] Agent that completed the plan.
@warning_ignore("unused_parameter")
func after_plan_complete(agent: GOAPAgent) -> void:
	pass
