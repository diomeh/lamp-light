## Goal: Gather resources and store them
class_name GatherAndStoreGoal
extends GOAPGoal


func _init() -> void:
	goal_name = "Gather and Store Resources"
	priority = 10.0
	desired_state = {
		"resource_stored": true
	}


func is_relevant(agent: GOAPAgent) -> bool:
	var entity = agent.actor.entity as ECSEntity
	if not entity:
		return false

	if not entity.has_component("InventoryComponent"):
		return false

	return can_store_resources()


func get_priority(agent: GOAPAgent) -> float:
	# Higher priority if inventory is empty (nothing to do otherwise)
	var entity = agent.actor.entity as ECSEntity
	var inventory = entity.get_component("InventoryComponent") as InventoryComponent

	if inventory and inventory.is_empty():
		return priority + 5.0

	return priority


func is_achieved(world_state: GOAPState) -> bool:
	return not can_store_resources() and super.is_achieved(world_state)


func after_plan_complete(agent: GOAPAgent) -> void:
	# We want to keep performin the action until we run of either resources or space
	if can_store_resources():
		agent.blackboard.set_value("resource_stored", false)


func can_store_resources() -> bool:
	var available_resources = ECSManager.find_entities_with_component(
		"ResourceComponent",
		func(e: ECSEntity):
			var res_comp = e.get_component("ResourceComponent") as ResourceComponent
			return res_comp != null and res_comp.can_harvest()
	)

	var available_storage = ECSManager.find_entities_with_component(
		"StorageComponent",
		func(e: ECSEntity):
			var storage = e.get_component("StorageComponent") as StorageComponent
			return storage != null and not storage.is_full()
	)

	return not available_resources.is_empty() and not available_storage.is_empty()
