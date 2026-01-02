## Component for entities that can store resources (warehouse, chest, etc.)
class_name StorageComponent
extends ECSComponent

## Maximum storage capacity (infinite if -1)
@export var max_capacity: int = 100

## Stored resources: {resource_type: amount}
var stored_resources: Dictionary[String, int] = {}


func _on_component_ready() -> void:
	component_name = "StorageComponent"


## Deposit resource into storage
## Returns amount actually stored
func deposit(resource_type: String, amount: int) -> int:
	var actual_amount: int

	if max_capacity > 0:
		var current_total = get_total_stored()
		var space_available = max_capacity - current_total
		actual_amount = min(amount, space_available)

		if actual_amount <= 0:
			return 0
	else:
		# Infinite capacity
		actual_amount = amount

	if not stored_resources.has(resource_type):
		stored_resources[resource_type] = 0

	stored_resources[resource_type] += actual_amount
	return actual_amount


## Withdraw resource from storage
## Returns amount actually withdrawn
func withdraw(resource_type: String, amount: int) -> int:
	if not stored_resources.has(resource_type):
		return 0

	var actual_amount = min(amount, stored_resources[resource_type])
	stored_resources[resource_type] -= actual_amount

	if stored_resources[resource_type] <= 0:
		stored_resources.erase(resource_type)

	return actual_amount


## Check if storage has specific resource
func has_resource(resource_type: String, min_amount: int = 1) -> bool:
	return stored_resources.get(resource_type, 0) >= min_amount


## Get amount of specific resource type
func get_amount(resource_type: String) -> int:
	return stored_resources.get(resource_type, 0)


## Get total amount of all stored resources
func get_total_stored() -> int:
	var total = 0
	for amount in stored_resources.values():
		total += amount
	return total


## Check if storage is full
func is_full() -> bool:
	return false if max_capacity <= 0 else get_total_stored() >= max_capacity


## Check if storage is empty
func is_empty() -> bool:
	return stored_resources.is_empty()
