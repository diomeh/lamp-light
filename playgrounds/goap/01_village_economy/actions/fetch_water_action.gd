## Action: Fetch water from the well.
##
## Requires being at the well location.[br]
## Takes time to complete and costs stamina.
extends GOAPAction
class_name FetchWaterAction

var _fetch_timer: float = 0.0
var _fetch_duration: float = 2.5


func _init() -> void:
	action_name = &"FetchWater"
	cost = 2.0
	preconditions = {
		&"at_location": &"well",
		&"has_water": false
	}
	effects = {
		&"has_water": true
	}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	# Need to be at well and have enough stamina
	var at_well: bool = state.get(&"at_location") == &"well"
	var has_stamina: bool = state.get(&"stamina", 0.0) as float > 20.0
	var no_water: bool = not state.get(&"has_water", false)
	return at_well and has_stamina and no_water


func enter(_agent: GOAPAgent) -> void:
	_fetch_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_fetch_timer += delta

	# Consume stamina while fetching
	var villager := agent as VillagerAgent
	if villager:
		villager.stamina = maxf(villager.stamina - delta * 5.0, 0.0)
		agent.blackboard.set_value(&"stamina", villager.stamina)

	if _fetch_timer >= _fetch_duration:
		# Fetching complete
		agent.blackboard.set_value(&"has_water", true)
		if villager:
			villager.has_water = true
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_fetch_timer = 0.0
