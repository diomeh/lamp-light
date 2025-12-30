@abstract
class_name GOAPGoal
extends Resource

## Abstract base class for all GOAP goals.
## Goals represent desired world states an agent wants to achieve.
## The planner will find a sequence of actions to satisfy the goal's desired state.

## The display name of this goal
@export var goal_name: String = "Unnamed Goal"

## The base priority of this goal. Higher priority goals are selected first.
@export var priority: float = 1.0

## Dictionary defining the desired world state for this goal to be satisfied.
@export var desired_state: Dictionary[String, Variant] = {}


## Checks if this goal has been achieved given the current world state.
## Returns true if all desired state conditions match the world state, false otherwise.
func is_achieved(world_state: GOAPState) -> bool:
	return world_state.matches_conditions(desired_state)


## Determine if this goal should be considered right now.
## Use this for context-sensitive goals (e.g., only consider "Rest" goal when health is low).
## Returns true if the goal is relevant, false otherwise.
@abstract
func is_relevant(agent: GOAPAgent) -> bool


## Dynamic priority calculation based on the agent's current situation.
## By default, returns the static priority value.
## Override to implement dynamic priority based on blackboard or agent state.
## Returns the calculated priority value.
func get_priority(_agent: GOAPAgent) -> float:
	return priority
