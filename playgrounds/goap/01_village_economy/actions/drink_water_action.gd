## Action: Drink water to reduce thirst.
##
## Requires having water in inventory.[br]
## Can be done anywhere, instantly reduces thirst.
extends GOAPAction
class_name DrinkWaterAction

var _drink_timer: float = 0.0
var _drink_duration: float = 1.0


func _init() -> void:
	action_name = &"DrinkWater"
	cost = 1.0
	preconditions = {
		&"has_water": true
	}
	effects = {
		&"thirst": 0,
		&"has_water": false
	}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"has_water", false) as bool


func enter(_agent: GOAPAgent) -> void:
	_drink_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_drink_timer += delta

	if _drink_timer >= _drink_duration:
		# Drinking complete - reduce thirst significantly
		var villager := agent as VillagerAgent
		if villager:
			villager.thirst = maxf(villager.thirst - 70.0, 0.0)
			villager.has_water = false
			agent.blackboard.set_value(&"thirst", villager.thirst)
			agent.blackboard.set_value(&"has_water", false)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_drink_timer = 0.0
