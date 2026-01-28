## Action: Move to a specific location.
##
## Generic movement action that transports agent between locations.[br]
## Used as prerequisite for gathering and other location-based actions.
extends GOAPAction
class_name MoveToAction

## Target location to move to.
var target_location: StringName

## Target position within the location (randomized on enter).
var _target_position: Vector2 = Vector2.ZERO

## Arrival threshold (distance at which we consider movement complete).
var _arrival_threshold: float = 10.0


func _init(location: StringName = &"village") -> void:
	target_location = location
	action_name = StringName("MoveTo_%s" % target_location)
	cost = 1.0
	preconditions = {}  # Can always attempt to move
	effects = {&"at_location": target_location}


func can_execute(state: Dictionary[StringName, Variant]) -> bool:
	# Can't move if already at location
	return state.get(&"at_location") != target_location


func enter(agent: GOAPAgent) -> void:
	# Get a random position within the target location
	var village_economy := agent.actor.get_parent() as Node
	if village_economy and village_economy.has_method("get_random_location_position"):
		_target_position = village_economy.get_random_location_position(target_location)
	else:
		_target_position = Vector2.ZERO


func execute(agent: GOAPAgent, delta: float) -> ExecResult:
	var villager := agent as VillagerAgent
	if not villager:
		return ExecResult.FAILURE

	# Move toward target using physics-based movement
	var distance := villager.move_toward(_target_position, delta)

	# Check if arrived
	if distance <= _arrival_threshold:
		agent.blackboard.set_value(&"at_location", target_location)
		return ExecResult.SUCCESS

	return ExecResult.RUNNING


func exit(_agent: GOAPAgent) -> void:
	_target_position = Vector2.ZERO
