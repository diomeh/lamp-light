## Abstract base class for GOAP sensors.
##
## Sensors are the mandatory bridge between WorldState events and agent Blackboards.[br]
## They subscribe to SignalBus events, apply perception rules, and write beliefs.[br][br]
##
## [b]Architectural Role:[/b][br]
## [codeblock]
## WorldState → SignalBus → Sensors → Blackboard → GOAP
## [/codeblock][br]
##
## [b]Perception Rules:[/b][br]
## - Line of sight[br]
## - Distance/range[br]
## - Ownership/faction[br]
## - Access rights[br]
## - Timing/memory decay[br][br]
##
## [b]Critical Constraints:[/b][br]
## - Sensors are the ONLY path from WorldState to Blackboard[br]
## - Sensors NEVER write to WorldState[br]
## - Sensors NEVER expose WorldState directly to GOAP[br]
## - Multiple agents may have different beliefs about the same truth[br][br]
##
## [b]Example implementation:[/b]
## [codeblock]
## class_name VisionSensor
## extends GOAPSensor
##
## func _init() -> void:
##     sensor_name = "Vision"
##     max_range = 100.0
##
## func _ready() -> void:
##     super._ready()
##     SignalBus.component_changed.connect(_on_component_changed)
##
## func can_perceive(source: Vector3) -> bool:
##     var distance = agent.actor.global_position.distance_to(source)
##     return distance <= max_range and has_line_of_sight(source)
##
## func _on_component_changed(entity_id: int, component_type: String, value: Variant) -> void:
##     if not can_perceive(get_entity_position(entity_id)):
##         return
##
##     # Update belief based on perceived change
##     agent.blackboard.set_value("enemy_position", value)
## [/codeblock][br]
##
## See also:[br]
## [GOAPAgent][br]
## [GOAPState][br]
@abstract
class_name GOAPSensor
extends Node

## Display name for debugging.
@export var sensor_name: String = "Unnamed Sensor"

## Whether this sensor is currently active.
@export var enabled: bool = true

## The agent this sensor feeds beliefs to.[br]
## Set automatically in [method _ready].
var agent: GOAPAgent

## Called when sensor is added to the scene tree.[br]
## Automatically finds parent [GOAPAgent].[br]
## Override to subscribe to SignalBus signals.
func _ready() -> void:
	agent = get_parent() as GOAPAgent
	assert(agent != null, "GOAPSensor must be a child of GOAPAgent")
	_subscribe_to_signals()


## Subscribe to relevant SignalBus signals.[br][br]
##
## Override to connect to specific signals:[br]
## [codeblock]
## func _subscribe_to_signals() -> void:
##     SignalBus.component_changed.connect(_on_component_changed)
##     SignalBus.entity_spawned.connect(_on_entity_spawned)
## [/codeblock]
@abstract
func _subscribe_to_signals() -> void


## Determines if this sensor can perceive an event from a source.[br][br]
##
## Override to implement perception rules like:[br]
## - Distance checks[br]
## - Line of sight validation[br]
## - Faction/ownership filtering[br]
## - Access rights[br][br]
##
## [param source_position] World position of the perceived event/entity.[br]
## Returns [code]true[/code] if event can be perceived, [code]false[/code] otherwise.
@warning_ignore("unused_parameter")
func can_perceive(source_position: Vector3) -> bool:
	return enabled


## Updates agent's blackboard with perceived belief.[br][br]
##
## This is the primary method for writing beliefs.[br]
## Called after [method can_perceive] returns [code]true[/code].[br][br]
##
## [b]Examples:[/b][br]
## [codeblock]
## # Update simple belief
## update_belief("enemy_spotted", true)
##
## # Update complex belief
## update_belief("last_known_enemy_position", enemy_pos)
## update_belief("last_seen_time", Time.get_ticks_msec())
## [/codeblock][br][br]
##
## [param key] Belief key in the blackboard.[br]
## [param value] Belief value to store.
func update_belief(key: String, value: Variant) -> void:
	if not agent or not enabled:
		return

	agent.blackboard.set_value(key, value)


## Removes a belief from the agent's blackboard.[br][br]
##
## Useful for implementing forgetting/memory decay.[br][br]
##
## [param key] Belief key to remove.
func forget_belief(key: String) -> void:
	if not agent or not enabled:
		return

	agent.blackboard.remove_value(key)


## Checks if agent already has a belief.[br][br]
##
## [param key] Belief key to check.[br]
## Returns [code]true[/code] if belief exists in blackboard.
func has_belief(key: String) -> bool:
	if not agent or not enabled:
		return false

	return agent.blackboard.has_value(key)


## Gets current belief value.[br][br]
##
## [param key] Belief key to retrieve.[br]
## [param default] Value returned if belief doesn't exist.[br]
## Returns stored belief or [param default].
func get_belief(key: String, default: Variant = null) -> Variant:
	if not agent or not enabled:
		return default

	return agent.blackboard.get_value(key, default)
