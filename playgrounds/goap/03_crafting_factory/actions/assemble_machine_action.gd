## Action: Assemble machine from gears and tools (Tier 5).
##
## Requires: 3 gear + 2 tool → Produces: 1 machine
extends GOAPAction
class_name AssembleMachineAction

var _craft_timer: float = 0.0
var _craft_duration: float = 12.0
var _target_station: CraftingStation = null


func _init() -> void:
	action_name = &"AssembleMachine"
	cost = 6.0
	preconditions = {&"gear": 3, &"tool": 2}
	effects = {&"gear": 0, &"tool": 0, &"machine": 1}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	return state.get(&"gear", 0) as int >= 3 and state.get(&"tool", 0) as int >= 2


func enter(agent: GOAPAgent) -> void:
	_craft_timer = 0.0
	var crafter := agent as CrafterAgent
	if crafter:
		var factory := crafter.actor.get_parent() as Node
		if factory and factory.has_method("find_available_station"):
			_target_station = factory.find_available_station(&"assembly")
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
			if crafter.remove_material(&"gear", 3) and crafter.remove_material(&"tool", 2):
				if crafter.add_material(&"machine", 1):
					return ExecResult.SUCCESS
			return ExecResult.FAILURE

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_craft_timer = 0.0
	if _target_station:
		_target_station.release()
		_target_station = null
