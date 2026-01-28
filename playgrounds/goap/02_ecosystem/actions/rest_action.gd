## Action: Rest to conserve energy (predator).
##
## Stands still and slowly regenerates energy.
extends GOAPAction
class_name PredatorRestAction

var _rest_duration: float = 5.0
var _rest_timer: float = 0.0


func _init() -> void:
	action_name = &"Rest"
	cost = 1.0
	preconditions = {}
	effects = {&"rested": true}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value >= 70.0


func enter(agent: GOAPAgent) -> void:
	_rest_timer = 0.0
	agent.blackboard.set_value(&"rested", false)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	_rest_timer += delta

	var creature := agent as CreatureAgent
	if creature:
		# Slowly regenerate energy while resting
		creature.energy = minf(creature.energy + delta * 3.0, 100.0)
		agent.blackboard.set_value(&"energy", creature.energy)

	if _rest_timer >= _rest_duration:
		agent.blackboard.set_value(&"rested", true)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_rest_timer = 0.0
