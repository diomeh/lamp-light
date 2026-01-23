## NPC behavior test scene for GOAP integration tests.
##
## Simulates a simple NPC with survival behavior (hunger -> find food -> eat).[br]
## Tests complete behavior loops with scene tree.
extends Node


func _ready() -> void:
	_configure_npc($NPC)


func _configure_npc(npc: Node) -> void:
	if not npc:
		return

	var agent := npc as GOAPAgent
	if not agent:
		return

	# Set up initial state (NPC is hungry)
	agent.blackboard.set_value(&"hunger", 50)
	agent.blackboard.set_value(&"has_food", false)

	# Create survival goal
	var survive_goal := MockGoal.new()
	survive_goal.goal_name = &"Survive"
	survive_goal.dynamic_desired_state = func(_state: Dictionary[StringName, Variant]) -> Dictionary[StringName, Variant]:
		return {&"hunger": 0}
	survive_goal.priority = 10.0

	# Create actions
	var find_food := MockAction.new()
	find_food.action_name = &"FindFood"
	find_food.effects = {&"has_food": true}
	find_food.cost = 2.0
	find_food.mock_result = GOAPAction.ExecResult.SUCCESS

	var eat := MockAction.new()
	eat.action_name = &"Eat"
	eat.preconditions = {&"has_food": true}
	eat.effects = {&"hunger": 0, &"has_food": false}
	eat.cost = 1.0
	eat.mock_result = GOAPAction.ExecResult.SUCCESS

	agent.goals = [survive_goal]
	agent.actions = [find_food, eat]
