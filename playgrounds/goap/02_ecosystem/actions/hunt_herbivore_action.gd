## Action: Hunt and kill herbivore (predator).
##
## Chases prey, kills on contact, and eats.
extends GOAPAction
class_name HuntHerbivoreAction

var _hunt_timer: float = 0.0
var _max_hunt_duration: float = 10.0  # Give up after 10 seconds
var _eating_duration: float = 3.0
var _eating_timer: float = 0.0
var _is_eating: bool = false


func _init() -> void:
	action_name = &"HuntHerbivore"
	cost = 3.0
	preconditions = {&"prey_detected": true}
	effects = {&"energy": 90}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	var energy_value := state.get(&"energy", 50.0) as float
	var prey_detected := state.get(&"prey_detected", false) as bool
	return energy_value < 90.0 and prey_detected


func enter(_agent: GOAPAgent) -> void:
	_hunt_timer = 0.0
	_eating_timer = 0.0
	_is_eating = false


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var predator := agent as Predator
	if not predator:
		return ExecResult.FAILURE

	# Check if prey still exists and is alive
	if not predator.target_creature or not is_instance_valid(predator.target_creature) or predator.target_creature.is_dead:
		return ExecResult.FAILURE

	_hunt_timer += delta

	if _hunt_timer > _max_hunt_duration:
		# Hunt took too long, give up
		return ExecResult.FAILURE

	if _is_eating:
		# Eating phase
		_eating_timer += delta

		# Restore energy while eating
		predator.eat(delta * 25.0)  # 25 energy per second while eating

		if _eating_timer >= _eating_duration or predator.energy >= 95.0:
			return ExecResult.SUCCESS

		return ExecResult.RUNNING
	else:
		# Chase phase
		var prey := predator.target_creature
		var distance := predator.move_toward(prey.actor.global_position, delta)

		# Consume energy while hunting
		predator.energy = maxf(predator.energy - delta * 4.0, 0.0)
		agent.blackboard.set_value(&"energy", predator.energy)

		# Kill prey if close enough
		if distance < 15.0:
			prey.die()
			_is_eating = true
			_eating_timer = 0.0

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_hunt_timer = 0.0
	_eating_timer = 0.0
	_is_eating = false
