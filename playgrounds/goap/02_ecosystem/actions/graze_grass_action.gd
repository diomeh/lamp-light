## Action: Graze on nearby grass patch (herbivore).
##
## Finds and consumes grass to restore energy.
extends GOAPAction
class_name GrazeGrassAction

var _graze_duration: float = 4.0
var _graze_timer: float = 0.0
var _target_grass_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	action_name = &"GrazeGrass"
	cost = 2.0
	preconditions = {}
	effects = {&"energy": 80}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	return energy_value < 80.0


func enter(agent: GOAPAgent) -> void:
	_graze_timer = 0.0

	# Find nearest grass patch
	var creature := agent as CreatureAgent
	if creature:
		var ecosystem := creature.actor.get_parent() as Node
		if ecosystem and ecosystem.has_method("find_nearest_grass"):
			_target_grass_pos = ecosystem.find_nearest_grass(creature.actor.global_position)


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var creature := agent as CreatureAgent
	if not creature:
		return ExecResult.FAILURE

	# Move toward grass patch
	var distance := creature.move_toward(_target_grass_pos, delta)

	if distance < 10.0:
		# At grass patch - graze
		_graze_timer += delta

		# Restore energy while grazing
		creature.eat(delta * 15.0)  # 15 energy per second

		# Notify ecosystem to deplete grass
		var ecosystem := creature.actor.get_parent() as Node
		if ecosystem and ecosystem.has_method("consume_grass"):
			ecosystem.consume_grass(_target_grass_pos, delta * 2.0)

		if _graze_timer >= _graze_duration or creature.energy >= 80.0:
			return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_graze_timer = 0.0
