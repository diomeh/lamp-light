## Base class for GOAP sensors that update agent beliefs.
##
## Sensors translate [WorldState] changes into agent [member GOAPAgent.blackboard] beliefs.[br]
## They subscribe to [SignalBus] signals and update beliefs based on perception filters.[br][br]
##
## [b]Architecture:[/b][br]
## - Sensors bridge WorldState (truth) and Blackboard (beliefs)[br]
## - Implement perception filtering (distance, visibility, etc.)[br]
## - Must be children of [GOAPAgent] nodes[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## extends GOAPSensor
##
## func _subscribe_to_signals() -> void:
##     SignalBus.world_state_changed.connect(_on_world_state_changed)
##
## func _on_world_state_changed(key: String, value: Variant, position: Vector3) -> void:
##     if can_perceive(position):
##         update_belief(key, value)
## [/codeblock]
## [br]
## See also: [GOAPAgent], [WorldState], [SignalBus]
class_name GOAPSensor
extends Node

## Display name for debugging.
@export var sensor_name: String = "Unnamed Sensor"

## Whether this sensor is currently active.
@export var enabled: bool = true

## The agent this sensor feeds beliefs to.[br]
## Set automatically in [method _ready].
var agent: GOAPAgent

func _ready() -> void:
	agent = get_parent() as GOAPAgent
	assert(agent != null, "GOAPSensor must be a child of GOAPAgent")
	_subscribe_to_signals()


## Override to connect to [SignalBus] signals.[br][br]
##
## Called during [method _ready] after agent reference is set.[br]
## Subscribe to relevant signals and call perception methods.
func _subscribe_to_signals() -> void:
	pass


## Determines if this sensor can perceive an event at the given position.[br][br]
##
## Override to implement perception filtering (distance, line of sight, etc.).[br]
## Default implementation only checks if sensor is enabled.[br][br]
##
## [param source_position] World position of the event source.[br]
## [br]
## Returns [code]true[/code] if event should be perceived.
@warning_ignore("unused_parameter")
func can_perceive(source_position: Vector3) -> bool:
	return enabled


## Updates a belief in the agent's blackboard.[br][br]
##
## [param key] Belief key to set.[br]
## [param value] New belief value.
func update_belief(key: String, value: Variant) -> void:
	if not agent or not enabled:
		return

	agent.blackboard.set_value(key, value)


## Removes a belief from the agent's blackboard.[br][br]
##
## [param key] Belief key to remove.
func forget_belief(key: String) -> void:
	if not agent or not enabled:
		return

	agent.blackboard.remove_value(key)


## Checks if agent has a specific belief.[br][br]
##
## [param key] Belief key to check.[br]
## [br]
## Returns [code]true[/code] if belief exists.
func has_belief(key: String) -> bool:
	if not agent or not enabled:
		return false

	return agent.blackboard.has_value(key)


## Gets a belief value from the agent's blackboard.[br][br]
##
## [param key] Belief key to retrieve.[br]
## [param default] Value returned if belief doesn't exist.[br]
## [br]
## Returns belief value or [param default].
func get_belief(key: String, default: Variant = null) -> Variant:
	if not agent or not enabled:
		return default

	return agent.blackboard.get_value(key, default)
