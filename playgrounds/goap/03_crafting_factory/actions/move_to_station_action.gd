## Action: Move to a specific station type.
##
## Generic movement action for logistics.
extends GOAPAction
class_name MoveToStationAction

var _station_type: StringName = &"storage"
var _target_pos: Vector2 = Vector2.ZERO


func _init(station: StringName = &"storage") -> void:
	_station_type = station
	action_name = StringName("MoveTo_%s" % station)
	cost = 1.0
	preconditions = {}
	effects = {&"at_station": station}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"at_station") != _station_type


func enter(agent: GOAPAgent) -> void:
	var crafter := agent as CrafterAgent
	if crafter:
		var factory := crafter.actor.get_parent() as Node
		if factory and factory.has_method("find_available_station"):
			var station: CraftingStation = factory.find_available_station(_station_type)
			if station:
				_target_pos = station.get_work_position()


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var crafter := agent as CrafterAgent
	if not crafter:
		return ExecResult.FAILURE

	var distance := crafter.move_toward(_target_pos, delta)

	if distance < 10.0:
		agent.blackboard.set_value(&"at_station", _station_type)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	pass
