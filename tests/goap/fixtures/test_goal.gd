extends GOAPGoal
## Simple test goal.

func _init() -> void:
	goal_name = &"TestGoal"
	desired_state = {&"test_complete": true}
