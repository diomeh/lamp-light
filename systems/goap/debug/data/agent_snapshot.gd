## Agent state snapshot for replay and analysis.
##
## Captures complete agent state at a point in time.[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var snapshot := AgentSnapshot.create_from_agent(agent)
## print("Agent was in state: ", GOAPAgent.State.keys()[snapshot.state])
## print("Blackboard had ", snapshot.blackboard.size(), " entries")
## [/codeblock]
class_name AgentSnapshot
extends Resource

## Timestamp when snapshot was taken (seconds).
var timestamp: float = 0.0

## Agent name.
var agent_name: String = ""

## Agent FSM state.
var state: GOAPAgent.State = GOAPAgent.State.IDLE

## Blackboard contents (dictionary copy).
var blackboard: Dictionary = {}

## Current goal (null if none).
var current_goal: GOAPGoal = null

## Current action (null if none).
var current_action: GOAPAction = null

## Current plan (array of actions).
var plan: Array[GOAPAction] = []

## Current position in plan (0-indexed).
var plan_progress: int = 0


## Creates snapshot from agent.[br][br]
##
## [param agent] Agent to snapshot.[br]
## [br]
## Returns new AgentSnapshot.
static func create_from_agent(agent: GOAPAgent) -> AgentSnapshot:
	var snapshot := AgentSnapshot.new()
	snapshot.timestamp = Time.get_ticks_msec() / 1000.0
	snapshot.agent_name = agent.name
	snapshot.state = agent.get_state()
	snapshot.blackboard = agent.blackboard.to_dict()
	snapshot.current_goal = agent.current_goal
	snapshot.current_action = agent.get_current_action()

	# Get plan from executor if available
	if agent._executor and agent._executor.is_running():
		snapshot.plan_progress = agent._executor.get_current_index()
		# Note: _plan is private, we'd need to expose it or reconstruct from events

	return snapshot


## Converts to dictionary for serialization.[br][br]
##
## Returns dictionary representation.
func to_dict() -> Dictionary[String, Variant]:
	return {
		"timestamp": timestamp,
		"agent_name": agent_name,
		"state": GOAPAgent.State.keys()[state],
		"blackboard": blackboard,
		"current_goal": current_goal.goal_name,
		"current_action": current_action.action_name,
		"plan_size": plan.size(),
		"plan_progress": plan_progress
	}
