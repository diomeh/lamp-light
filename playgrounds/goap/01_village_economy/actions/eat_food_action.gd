## Action: Eat food to reduce hunger.
##
## Requires having food in inventory.[br]
## Can be done anywhere, instantly reduces hunger.
extends GOAPAction
class_name EatFoodAction

var _eat_timer: float = 0.0
var _eat_duration: float = 1.5


func _init() -> void:
	action_name = &"EatFood"
	cost = 1.0
	preconditions = {
		&"has_food": true
	}
	effects = {
		&"hunger": 0,
		&"has_food": false
	}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"has_food", false) as bool


func enter(_agent: GOAPAgent) -> void:
	_eat_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_eat_timer += delta

	if _eat_timer >= _eat_duration:
		# Eating complete - reduce hunger significantly
		var villager := agent as VillagerAgent
		if villager:
			villager.hunger = maxf(villager.hunger - 60.0, 0.0)
			villager.has_food = false
			agent.blackboard.set_value(&"hunger", villager.hunger)
			agent.blackboard.set_value(&"has_food", false)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_eat_timer = 0.0
