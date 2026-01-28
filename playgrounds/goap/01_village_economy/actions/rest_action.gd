## Action: Rest to restore stamina.
##
## Requires being at village location.[br]
## Takes time and steadily restores stamina.
extends GOAPAction
class_name RestAction

var _rest_timer: float = 0.0
var _rest_duration: float = 4.0


func _init() -> void:
	action_name = &"Rest"
	cost = 1.0
	preconditions = {
		&"at_location": &"village"
	}
	effects = {
		&"stamina": 100
	}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var at_village: bool = state.get(&"at_location") == &"village"
	var low_stamina: bool = state.get(&"stamina", 100.0) as float < 80.0
	return at_village and low_stamina


func enter(_agent: GOAPAgent) -> void:
	_rest_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_rest_timer += delta

	# Restore stamina while resting
	var villager := agent as VillagerAgent
	if villager:
		villager.stamina = minf(villager.stamina + delta * 25.0, 100.0)
		agent.blackboard.set_value(&"stamina", villager.stamina)

	if _rest_timer >= _rest_duration or (villager and villager.stamina >= 95.0):
		# Resting complete
		if villager:
			villager.stamina = 100.0
			agent.blackboard.set_value(&"stamina", 100.0)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_rest_timer = 0.0
