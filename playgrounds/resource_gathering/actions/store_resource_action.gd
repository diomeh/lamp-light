## Action: Store gathered resources in storage
class_name StoreResourceAction
extends GOAPAction

## Time to store resources (in seconds)
const STORE_TIME: float = 0.3

var store_timer: float = 0.0


func _init() -> void:
	action_name = "Store Resource"
	cost = 1.0
	preconditions = {"has_resource": true, "near_storage": true}
	effects = {"resource_stored": true, "has_resource": false}


func can_perform(agent: GOAPAgent) -> bool:
	var entity = agent.actor.entity as ECSEntity
	if not entity:
		return false

	# Need inventory with resources
	var inventory = entity.get_component("InventoryComponent") as InventoryComponent
	if not inventory or inventory.is_empty():
		return false

	# Need valid target storage
	var target_storage = agent.blackboard.get_value("target_storage") as ECSEntity
	if not target_storage:
		return false

	var storage = target_storage.get_component("StorageComponent") as StorageComponent
	return storage != null and not storage.is_full()


func enter(agent: GOAPAgent) -> void:
	super.enter(agent)
	store_timer = 0.0


func perform(agent: GOAPAgent, delta: float) -> bool:
	var entity = agent.actor.entity as ECSEntity
	var inventory = entity.get_component("InventoryComponent") as InventoryComponent
	var target_storage = agent.blackboard.get_value("target_storage") as ECSEntity

	if not target_storage or not inventory:
		return true # Failed

	var storage = target_storage.get_component("StorageComponent") as StorageComponent
	if not storage:
		return true # Failed

	# Wait for store time
	store_timer += delta
	if store_timer < STORE_TIME:
		return false # Still storing

	# Transfer all resources from inventory to storage
	var total_stored = 0
	for resource_type in inventory.inventory.keys():
		var amount = inventory.inventory[resource_type]
		var stored = storage.deposit(resource_type, amount)
		inventory.remove_resource(resource_type, stored)
		total_stored += stored

	print("%s stored %d resources" % [entity.entity_id, total_stored])

	# Update blackboard
	agent.blackboard.set_value("has_resource", false)
	agent.blackboard.set_value("resource_stored", true)

	return true


func exit(agent: GOAPAgent) -> void:
	super.exit(agent)
	store_timer = 0.0
