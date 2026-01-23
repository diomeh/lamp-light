## Multi-agent test scene for GOAP integration tests.
##
## Scene with multiple agents for testing coordination and scheduling.
extends Node


func _ready() -> void:
	# Configure each agent with different goals
	_configure_agent($Agent1, &"Goal1", {&"done1": true})
	_configure_agent($Agent2, &"Goal2", {&"done2": true})
	_configure_agent($Agent3, &"Goal3", {&"done3": true})


func _configure_agent(agent: Node, goal_name: StringName, desired: Dictionary) -> void:
	if not agent or not agent.has_method("set"):
		return

	var goap_agent := agent as GOAPAgent
	if goap_agent:
		var goal := MockGoal.new()
		goal.goal_name = goal_name
		goal.dynamic_desired_state = func(_state: Dictionary[StringName, Variant]) -> Dictionary[StringName, Variant]:
			return desired
		goal.priority = 1.0

		var action := MockAction.new()
		action.action_name = ("Action_%s" % goal_name) as StringName
		action.effects = desired
		action.mock_result = GOAPAction.ExecResult.SUCCESS

		goap_agent.goals = [goal]
		goap_agent.actions = [action]
		goap_agent.blackboard.set_value(&"agent_id", goal_name)
