## Action: Smelt iron ingot from ore (Tier 2).
##
## Requires: 1 ore → Produces: 1 iron_ingot
extends GOAPAction
class_name SmeltIngotAction

var _craft_timer: float = 0.0
var _craft_duration: float = 3.0
var _target_station: CraftingStation = null


func _init() -> void:
	action_name = &"SmeltIngot"
	cost = 3.0
	preconditions = {&"ore": 1}
	effects = {&"ore": 0, &"iron_ingot": 1}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"ore", 0) as int >= 1


func enter(agent: GOAPAgent) -> void:
	_craft_timer = 0.0
	var crafter := agent as CrafterAgent
	if crafter:
		var factory := crafter.actor.get_parent() as Node
		if factory and factory.has_method("find_available_station"):
			_target_station = factory.find_available_station(&"furnace")
			if _target_station:
				_target_station.reserve(crafter)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var crafter := agent as CrafterAgent
	if not crafter or not _target_station:
		return ExecResult.FAILURE

	# Move to station
	var distance := crafter.move_toward(_target_station.get_work_position(), delta)

	if distance < 10.0:
		# At station - craft
		_craft_timer += delta

		if _craft_timer >= _craft_duration:
			# Crafting complete
			if crafter.remove_material(&"ore", 1):
				if crafter.add_material(&"iron_ingot", 1):
					return ExecResult.SUCCESS
			return ExecResult.FAILURE

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_craft_timer = 0.0
	if _target_station:
		_target_station.release()
		_target_station = null
