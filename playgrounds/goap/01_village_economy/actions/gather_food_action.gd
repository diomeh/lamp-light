## Action: Gather food from the field.
##
## Requires being at the field location.[br]
## Takes time to complete and costs stamina.
extends GOAPAction
class_name GatherFoodAction

var _gather_timer: float = 0.0
var _gather_duration: float = 3.0


func _init() -> void:
	action_name = &"GatherFood"
	cost = 2.0
	preconditions = {
		&"at_location": &"field",
		&"has_food": false
	}
	effects = {
		&"has_food": true
	}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	# Need to be at field and have enough stamina
	var at_field: bool = state.get(&"at_location") == &"field"
	var has_stamina: bool = state.get(&"stamina", 0.0) as float > 20.0
	var no_food: bool = not state.get(&"has_food", false)
	return at_field and has_stamina and no_food


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
		agent.blackboard.set_value(&"has_food", true)
		if villager:
			villager.has_food = true
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_gather_timer = 0.0
