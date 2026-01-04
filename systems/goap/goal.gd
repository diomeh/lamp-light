## Abstract base class for GOAP goals.
##
## Goals represent desired world states.
## The [GOAPPlanner] finds action sequences
## to satisfy [member desired_state] conditions.[br][br]
##
## [b]Example implementation:[/b]
## [codeblock]
## class_name RestGoal
## extends GOAPGoal
##
## func _init() -> void:
##     goal_name = "Rest"
##     priority = 5.0
##     desired_state = {"is_rested": true}
##
## func is_relevant(agent: GOAPAgent) -> bool:
##     return agent.blackboard.get_value("energy", 100) < 30
## [/codeblock][br]
##
## See also:[br]
## [GOAPAgent][br]
## [GOAPPlanner][br]
@abstract
class_name GOAPGoal
extends Resource

## Display name.
@export var goal_name: String = "Unnamed Goal"

## Base priority value. Higher values are selected first.[br]
## Override [method get_priority] for dynamic priority.
@export var priority: float = 1.0

## Conditions that must be true for this goal to be satisfied.[br]
## The [GOAPPlanner] works backward from these conditions.
@export var desired_state: Dictionary[String, Variant] = {}


## Checks if goal is satisfied by given state.[br][br]
##
## [param state] The state to check against [member desired_state].[br]
## Returns [code]true[/code] if all conditions match, [code]false[/code] otherwise.
func is_achieved(state: GOAPState) -> bool:
	return state.matches_conditions(desired_state)


## Context-sensitive check if this goal should be considered.[br][br]
##
## Override to filter goals based on agent state (e.g., only consider
## "Rest" when energy is low).[br][br]
##
## [param agent] The agent evaluating this goal.[br]
## Returns [code]true[/code] if goal should be considered for planning.
@abstract
func is_relevant(agent: GOAPAgent) -> bool


## Dynamic priority calculation.[br][br]
##
## Override to implement situational priority (e.g., "Flee" priority
## increases as health decreases).[br][br]
##
## [param agent] The agent evaluating this goal.[br]
## Returns priority value; higher is more important.
@warning_ignore("unused_parameter")
func get_priority(agent: GOAPAgent) -> float:
	return priority


## Functionality to execute after a plan is sucessfully completed[be][br]
##
## Override to define any modifications to state after a plan is completed.
## Useful if a goal should make itself relevant again.[br][br]
##
## [param agent] The agent which completed the plan.
@warning_ignore("unused_parameter")
func after_plan_complete(agent: GOAPAgent) -> void:
	pass
