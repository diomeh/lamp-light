## Test scene for GOAP integration tests.
##
## Simple scene containing an agent with basic goals and actions[br]
## for testing scene tree integration.[br][br]
##
## [b]Included:[/b][br]
## - GOAPOrchestrator (autoload)[br]
## - GOAPAgent with simple goal/action setup[br]
## - Minimal actor structure
extends Node

const TestGoal = preload("res://tests/goap/fixtures/test_goal.gd")
const TestAction = preload("res://tests/goap/fixtures/test_action.gd")

@onready var agent: GOAPAgent = $Agent


func _ready() -> void:
	# Configure agent with test goal and action
	if agent:
		var goal := TestGoal.new()
		var action := TestAction.new()
		agent.goals = [goal]
		agent.actions = [action]
		agent.blackboard.set_value(&"initialized", true)
