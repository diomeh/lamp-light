## Action: Mine ore from mine station (Tier 1 - Raw material).
##
## Gathers ore from material source.
extends GOAPAction
class_name MineOreAction

var _mine_timer: float = 0.0
var _mine_duration: float = 2.0
var _target_station: CraftingStation = null


func _init() -> void:
	action_name = &"MineOre"
	cost = 2.0
	preconditions = {}
	effects = {&"ore": 1}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var space := state.get(&"inventory_space", 0) as int
	return space > 0


func enter(agent: GOAPAgent) -> void:
	_mine_timer = 0.0
	var crafter := agent as CrafterAgent
	if crafter:
		var factory := crafter.actor.get_parent() as Node
		if factory and factory.has_method("find_available_station"):
			_target_station = factory.find_available_station(&"mine")
			if _target_station:
				_target_station.reserve(crafter)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var crafter := agent as CrafterAgent
	if not crafter or not _target_station:
		return ExecResult.FAILURE

	# Move to station
	var distance := crafter.move_toward(_target_station.get_work_position(), delta)

	if distance < 10.0:
		# At station - mine
		_mine_timer += delta

		if _mine_timer >= _mine_duration:
			# Mining complete
			if crafter.add_material(&"ore", 1):
				return ExecResult.SUCCESS
			else:
				return ExecResult.FAILURE

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_mine_timer = 0.0
	if _target_station:
		_target_station.release()
		_target_station = null
