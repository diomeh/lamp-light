## Component for entities that can carry resources
class_name InventoryComponent
extends ECSComponent

## Maximum carrying capacity
@export var max_capacity: int = 10

## Current inventory: {resource_type: amount}
var inventory: Dictionary[String, int] = {}


func _on_component_ready() -> void:
	component_name = "InventoryComponent"


## Add resource to inventory
## Returns amount actually added (may be less than requested if full)
func add_resource(resource_type: String, amount: int) -> int:
	var current_total = get_total_amount()
	var space_available = max_capacity - current_total
	var actual_amount = min(amount, space_available)

	if actual_amount <= 0:
		return 0

	if not inventory.has(resource_type):
		inventory[resource_type] = 0

	inventory[resource_type] += actual_amount
	return actual_amount


## Remove resource from inventory
## Returns amount actually removed
func remove_resource(resource_type: String, amount: int) -> int:
	if not inventory.has(resource_type):
		return 0

	var actual_amount = min(amount, inventory[resource_type])
	inventory[resource_type] -= actual_amount

	if inventory[resource_type] <= 0:
		inventory.erase(resource_type)

	return actual_amount


## Check if inventory has specific resource
func has_resource(resource_type: String, min_amount: int = 1) -> bool:
	return inventory.get(resource_type, 0) >= min_amount


## Get amount of specific resource type
func get_amount(resource_type: String) -> int:
	return inventory.get(resource_type, 0)


## Get total amount of all resources
func get_total_amount() -> int:
	var total = 0
	for amount in inventory.values():
		total += amount
	return total


## Check if inventory is full
func is_full() -> bool:
	return get_total_amount() >= max_capacity


## Check if inventory is empty
func is_empty() -> bool:
	return inventory.is_empty()


## Clear all inventory
func clear() -> void:
	inventory.clear()
