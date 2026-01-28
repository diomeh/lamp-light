## Action: Gather wood from the forest.
##
## Requires being at the forest location.[br]
## Takes time to complete and costs stamina.
extends GOAPAction
class_name GatherWoodAction

var _gather_timer: float = 0.0
var _gather_duration: float = 3.5


func _init() -> void:
	action_name = &"GatherWood"
	cost = 2.5
	preconditions = {
		&"at_location": &"forest",
		&"has_wood": false
	}
	effects = {
		&"has_wood": true
	}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	# Need to be at forest and have enough stamina
	var at_forest: bool = state.get(&"at_location") == &"forest"
	var has_stamina: bool = state.get(&"stamina", 0.0) as float > 20.0
	var no_wood: bool = not state.get(&"has_wood", false)
	return at_forest and has_stamina and no_wood


func enter(_agent: GOAPAgent) -> void:
	_gather_timer = 0.0


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_gather_timer += delta

	# Consume stamina while gathering
	var villager := agent as VillagerAgent
	if villager:
		villager.stamina = maxf(villager.stamina - delta * 5.0, 0.0)
		agent.blackboard.set_value(&"stamina", villager.stamina)

	if _gather_timer >= _gather_duration:
		# Gathering complete
		agent.blackboard.set_value(&"has_wood", true)
		if villager:
			villager.has_wood = true
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_gather_timer = 0.0
