## Goal: Fulfill production order for a specific product.
##
## Dynamic priority based on order demand and production tier.[br]
## Higher tier products have higher priority.
extends GOAPGoal
class_name FulfillOrderGoal

## Product to produce.
var product: StringName

## Production tier (1-5, higher = more complex).
var tier: int


func _init(target_product: StringName = &"iron_ingot", production_tier: int = 2) -> void:
	product = target_product
	tier = production_tier
	goal_name = StringName("Fulfill_%s" % product)
	priority = float(tier) * 5.0  # Tier 5 = 25 priority, Tier 1 = 5 priority
	desired_state = {StringName("has_%s" % product): true}


func get_priority(state: Dictionary[StringName, Variant]) -> float:
	# Check if there's an active order for this product
	var factory := _get_factory(state)
	if not factory:
		return 0.0

	var orders: Dictionary = factory._active_orders
	if not orders.has(product) or orders[product] <= 0:
		return 0.0

	# Priority scales with order quantity and tier
	var order_quantity := orders[product] as int
	return priority * minf(order_quantity, 3.0)  # Cap scaling at 3x


func is_relevant(state: Dictionary[StringName, Variant]) -> bool:
	# Only relevant if there's an active order
	var factory := _get_factory(state)
	if not factory:
		return false

	var orders: Dictionary = factory._active_orders
	return orders.has(product) and orders[product] > 0


func is_achieved(state: Dictionary[StringName, Variant]) -> bool:
	# Achieved when product is in inventory (ready to deposit)
	return state.get(product, 0) as int > 0


## Helper to get factory reference from agent.
func _get_factory(_state: Dictionary[StringName, Variant]) -> Node:
	# This is a bit of a hack - in a real system, you'd pass factory reference
	# For now, we'll assume the agent can find it
	return null  # Will be handled in action execution
