## Global WorldState singleton - authoritative source of truth.
##
## Represents objective facts about the simulation.[br]
## Changes emit signals via SignalBus for sensors to perceive.[br][br]
##
## [b]Architecture Rules:[/b][br]
## - WorldState is data-only (no game logic)[br]
## - Only ECS systems may write to WorldState[br]
## - GOAP never reads WorldState directly[br]
## - Sensors translate WorldState changes into Blackboard beliefs[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## # System writes to WorldState
## WorldState.set_value("door_open", true, door_position)
##
## # Sensors listen via SignalBus
## SignalBus.world_state_changed.connect(_on_world_state_changed)
## [/codeblock][br]
##
## See also: [GOAPState], [GOAPSensor]
extends GOAPState


## Sets a world state value and emits change signal.[br][br]
##
## [b]Architecture:[/b] Only ECS systems should call this.[br][br]
##
## [param key] State key.[br]
## [param value] New value.[br]
## [param position] World position related to this change (for sensor filtering).
func set_value(key: String, value: Variant, position: Vector3 = Vector3.ZERO) -> void:
	super.set_value(key, value)
	SignalBus.world_state_changed.emit(key, value, position)


## Spawns an entity in the world.[br][br]
##
## Emits [signal SignalBus.entity_spawned] for sensors to perceive.[br][br]
##
## [param entity_id] Entity identifier.[br]
## [param entity_type] Type of entity (e.g., "enemy", "item", "light").[br]
## [param position] World position.
func spawn_entity(entity_id: int, entity_type: String, position: Vector3) -> void:
	SignalBus.entity_spawned.emit(entity_id, entity_type, position)


## Destroys an entity in the world.[br][br]
##
## Emits [signal SignalBus.entity_destroyed] for sensors to perceive.[br][br]
##
## [param entity_id] Entity identifier.[br]
## [param position] Last known position.
func destroy_entity(entity_id: int, position: Vector3) -> void:
	SignalBus.entity_destroyed.emit(entity_id, position)


## Updates a component value on an entity.[br][br]
##
## Emits [signal SignalBus.component_changed] for sensors to perceive.[br][br]
##
## [param entity_id] Entity identifier.[br]
## [param component_type] Component type name.[br]
## [param value] New component value.[br]
## [param position] Entity's world position.
func set_component(entity_id: int, component_type: String, value: Variant, position: Vector3) -> void:
	SignalBus.component_changed.emit(entity_id, component_type, value, position)
