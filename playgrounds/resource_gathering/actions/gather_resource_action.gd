## Action: Gather resource from target
class_name GatherResourceAction
extends GOAPAction

## Time to gather one unit (in seconds)
const GATHER_TIME: float = 0.5

## Amount to gather per action
const GATHER_AMOUNT: int = 5

var gather_timer: float = 0.0


func _init() -> void:
	action_name = "Gather Resource"
	cost = 2.0
	preconditions = {"near_resource": true}
	effects = {"has_resource": true}


func can_perform(agent: GOAPAgent) -> bool:
	var entity = agent.actor.entity as ECSEntity
	if not entity:
		return false

	# Need inventory component
	var inventory = entity.get_component("InventoryComponent") as InventoryComponent
	if not inventory or inventory.is_full():
		return false

	# Need valid target resource
	var target_resource = agent.blackboard.get_value("target_resource") as ECSEntity
	if not target_resource:
		return false

	var res_comp = target_resource.get_component("ResourceComponent") as ResourceComponent
	return res_comp != null and res_comp.can_harvest()


func enter(agent: GOAPAgent) -> void:
	super.enter(agent)
	gather_timer = 0.0


func perform(agent: GOAPAgent, delta: float) -> bool:
	var entity = agent.actor.entity as ECSEntity
	var inventory = entity.get_component("InventoryComponent") as InventoryComponent
	var target_resource = agent.blackboard.get_value("target_resource") as ECSEntity

	if not target_resource or not inventory:
		return true  # Failed

	var res_comp = target_resource.get_component("ResourceComponent") as ResourceComponent
	if not res_comp or not res_comp.can_harvest():
		return true  # Resource depleted

	# Wait for gather time
	gather_timer += delta
	if gather_timer < GATHER_TIME:
		return false  # Still gathering

	# Harvest resource
	var harvested = res_comp.harvest(GATHER_AMOUNT)
	var added = inventory.add_resource(res_comp.resource_type, harvested)

	print("%s gathered %d %s" % [entity.entity_id, added, res_comp.resource_type])

	# Update blackboard
	agent.blackboard.set_value("has_resource", true)
	agent.blackboard.set_value("resource_type", res_comp.resource_type)

	return true  # Done gathering


func exit(agent: GOAPAgent) -> void:
	super.exit(agent)
	gather_timer = 0.0
