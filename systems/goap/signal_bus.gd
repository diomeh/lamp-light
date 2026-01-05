## Stateless event transport system for GOAP architecture.
##
## Provides event communication between systems.[br]
## It stores NO state and contains NO domain logic.[br][br]
##
## See also: [WorldState], [GOAPSensor]
extends Node

@warning_ignore_start("unused_signal")

#region ECS → Sensors: Execution Result Signals

## Action execution completed successfully.[br][br]
##
## [param entity_id] Entity that performed the action.[br]
## [param action_type] Type of action (e.g., "move", "attack").[br]
## [param result_data] Optional result data (position reached, target hit, etc.).
signal action_succeeded(entity_id: int, action_type: String, result_data: Dictionary)

## Action execution failed.[br][br]
##
## [param entity_id] Entity that attempted the action.[br]
## [param action_type] Type of action that failed.[br]
## [param failure_reason] Why it failed (e.g., "path_blocked", "target_invalid").
signal action_failed(entity_id: int, action_type: String, failure_reason: String)

#endregion

#region WorldState → Sensors: State Change Signals

## Component value changed on an entity.[br][br]
##
## [param entity_id] Entity whose component changed.[br]
## [param component_type] Type of component.[br]
## [param value] New value.[br]
## [param position] World position of entity (for perception filtering).
signal component_changed(entity_id: int, component_type: String, value: Variant, position: Vector3)

## Entity was spawned in the world.[br][br]
##
## [param entity_id] ID of spawned entity.[br]
## [param entity_type] Type of entity (e.g., "enemy", "item").[br]
## [param position] Spawn position.
signal entity_spawned(entity_id: int, entity_type: String, position: Vector3)

## Entity was removed from the world.[br][br]
##
## [param entity_id] ID of removed entity.[br]
## [param position] Last known position.
signal entity_destroyed(entity_id: int, position: Vector3)

## World state value changed (global facts).[br][br]
##
## [param key] State key that changed.[br]
## [param value] New value.[br]
## [param position] Position related to change (for perception filtering).
signal world_state_changed(key: String, value: Variant, position: Vector3)

#endregion
