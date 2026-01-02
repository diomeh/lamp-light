## Component for entities that can be gathered (wood, food, stone, etc.)
class_name ResourceComponent
extends ECSComponent

## Type of resource (wood, food, stone, etc.)
@export var resource_type: String = "wood"

## Amount of resource available
@export var amount: int = 10

## Whether this resource has been depleted
var is_depleted: bool = false


func _on_component_ready() -> void:
	component_name = "ResourceComponent"

	# Add to world state so agents can find resources
	if entity:
		entity.metadata["resource_type"] = resource_type
		entity.metadata["amount"] = amount


## Harvest some amount from this resource
func harvest(amount_to_take: int) -> int:
	var actual_amount = min(amount_to_take, amount)
	amount -= actual_amount

	if amount <= 0:
		is_depleted = true
		entity.metadata["is_depleted"] = true

	entity.metadata["amount"] = amount
	return actual_amount


## Check if resource can be harvested
func can_harvest() -> bool:
	return amount > 0 and not is_depleted
