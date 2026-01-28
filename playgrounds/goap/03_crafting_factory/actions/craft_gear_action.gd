## Action: Craft gear from ingots and tool (Tier 4).
##
## Requires: 5 iron_ingot + 1 tool → Produces: 1 gear
extends GOAPAction
class_name CraftGearAction

var _craft_timer: float = 0.0
var _craft_duration: float = 8.0
var _target_station: CraftingStation = null


func _init() -> void:
	action_name = &"CraftGear"
	cost = 5.0
	preconditions = {&"iron_ingot": 5, &"tool": 1}
	effects = {&"iron_ingot": 0, &"tool": 0, &"gear": 1}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"iron_ingot", 0) as int >= 5 and state.get(&"tool", 0) as int >= 1


func enter(agent: GOAPAgent) -> void:
	_craft_timer = 0.0
	var crafter := agent as CrafterAgent
	if crafter:
		var factory := crafter.actor.get_parent() as Node
		if factory and factory.has_method("find_available_station"):
			_target_station = factory.find_available_station(&"factory")
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
			if crafter.remove_material(&"iron_ingot", 5) and crafter.remove_material(&"tool", 1):
				if crafter.add_material(&"gear", 1):
					return ExecResult.SUCCESS
			return ExecResult.FAILURE

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_craft_timer = 0.0
	if _target_station:
		_target_station.release()
		_target_station = null
