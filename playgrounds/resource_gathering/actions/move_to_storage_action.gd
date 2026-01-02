## Action: Move to storage location
class_name MoveToStorageAction
extends GOAPAction

## Distance considered "near" for storing
const STORE_DISTANCE: float = 2.0

var target_storage: ECSEntity = null


func _init() -> void:
	action_name = "Move to Storage"
	cost = 1.0
	preconditions = {"has_resource": true}
	effects = {"near_storage": true}


func can_perform(agent: GOAPAgent) -> bool:
	var entity = agent.actor.entity as ECSEntity
	if not entity:
		return false

	# Need inventory with resources
	var inventory = entity.get_component("InventoryComponent") as InventoryComponent
	if not inventory or inventory.is_empty():
		return false

	return true


func enter(agent: GOAPAgent) -> void:
	super.enter(agent)

	# Find nearest storage
	target_storage = ECSManager.find_nearest_entity_with_component(
		"StorageComponent",
		agent.actor.global_position,
		func(e: ECSEntity):
			var storage = e.get_component("StorageComponent") as StorageComponent
			return storage != null and not storage.is_full()
	)

	if target_storage:
		agent.blackboard.set_value("target_storage", target_storage)


func perform(agent: GOAPAgent, _delta: float) -> bool:
	if not target_storage:
		return true  # Failed

	var actor = agent.actor as Actor
	if not actor:
		return true

	# Get position from parent container
	var pos = target_storage.get_parent().global_position
	var distance = actor.global_position.distance_to(pos)

	# Check if we're close enough
	if distance <= STORE_DISTANCE:
		return true  # Success!

	# Move toward storage
	var move_speed = agent.blackboard.get_value("move_speed", 5.0)
	actor.move_toward(pos, move_speed)
	actor.look_toward(pos)

	return false  # Still moving


func exit(agent: GOAPAgent) -> void:
	super.exit(agent)
	var actor = agent.actor as Actor
	if actor:
		actor.stop_moving()
