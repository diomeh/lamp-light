## Action: Move to nearest available resource
class_name MoveToResourceAction
extends GOAPAction

## Distance considered "near" for gathering
const GATHER_DISTANCE: float = 2.0

## Target resource entity
var target_resource: ECSEntity = null


func _init() -> void:
	action_name = "Move to Resource"
	cost = 1.0
	preconditions = {}
	effects = {"near_resource": true}


func can_perform(agent: GOAPAgent) -> bool:
	# Check if agent has inventory component
	var entity = agent.actor.entity as ECSEntity
	if not entity:
		return false

	var inventory = entity.get_component("InventoryComponent") as InventoryComponent
	if not inventory:
		return false

	# Don't move if inventory is full
	if inventory.is_full():
		return false

	return true


func enter(agent: GOAPAgent) -> void:
	super.enter(agent)
	# Store target in blackboard for other actions to use

	# Find nearest resource that isn't depleted
	target_resource = ECSManager.find_nearest_entity_with_component(
		"ResourceComponent",
		agent.actor.global_position,
		func(e: ECSEntity):
			var res_comp = e.get_component("ResourceComponent") as ResourceComponent
			return res_comp != null and res_comp.can_harvest()
	)

	if target_resource:
		agent.blackboard.set_value("target_resource", target_resource)


func perform(agent: GOAPAgent, _delta: float) -> bool:
	if not target_resource:
		return true  # Failed, but complete action

	var actor = agent.actor as Actor
	if not actor:
		return true

	var pos = target_resource.get_parent().global_position
	var distance = actor.global_position.distance_to(pos)

	# Check if we're close enough
	if distance <= GATHER_DISTANCE:
		return true  # Success!

	# Move toward resource
	var move_speed = agent.blackboard.get_value("move_speed", 5.0)
	actor.move_toward(pos, move_speed)
	actor.look_toward(pos)

	return false  # Still moving


func exit(agent: GOAPAgent) -> void:
	super.exit(agent)
	var actor = agent.actor as Actor
	if actor:
		actor.stop_moving()
