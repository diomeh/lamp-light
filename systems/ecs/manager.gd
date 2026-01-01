## Manager for all ECS entities in the game.
##
## Provides fast querying and spatial lookups over entities.
extends Node

## Set of all registered entities
var entities: Dictionary[String, ECSEntity] = {}

## Set for fast component-based queries
var entities_by_component: Dictionary[String, Array] = {}

## Emitted when an entity is registered
signal entity_registered(entity: ECSEntity)

## Emitted when an entity is unregistered
signal entity_unregistered(entity: ECSEntity)


## Registers an entity with the manager
func register_entity(entity: ECSEntity) -> void:
	if entities.has(entity.entity_id):
		push_warning("ECSEntity with ID '%s' already registered" % entity.entity_id)
		return

	entities[entity.entity_id] = entity

	# Index by components
	for component_name in entity.components.keys():
		if not entities_by_component.has(component_name):
			entities_by_component[component_name] = []
		entities_by_component[component_name].append(entity)

	entity_registered.emit(entity)


## Unregisters an entity from the manager
func unregister_entity(entity: ECSEntity) -> void:
	if not entities.has(entity.entity_id):
		return

	entities.erase(entity.entity_id)

	# Remove from component indices
	for component_name in entity.components.keys():
		if not entities_by_component.has(component_name): continue
		entities_by_component[component_name].erase(entity)
		if entities_by_component[component_name].is_empty():
			entities_by_component.erase(component_name)

	entity_unregistered.emit(entity)


## Gets an entity by its ID
func get_entity(entity_id: String) -> ECSEntity:
	return entities.get(entity_id)


## Gets all entities that have specific component[br][br]
##
## Uses a callback as a criteron to determine
## which entities should be returned.[br]
##
## [codeblock]
## var entities = ECSManager.find_entities_with_component(
##     "HealthComponent",
##     func(e: ECSEntity): return e.get_health() > 0
## )
## [/codeblock][br]
##
## [param component_name] The name of the component entities must have.[br]
## [param filter] Callback function to filter entities by. Optional.[br]
## Returns an array of [ECSEntity] that pass filter function.
func find_entities_with_component(
	component_name: String,
	filter: Callable = func(_e: ECSEntity): return true
) -> Array[ECSEntity]:
	if entities_by_component.has(component_name):
		return entities_by_component[component_name].filter(filter)
	else:
		return [] as Array[ECSEntity]


## Finds the nearest entity with a specific component.[br][br]
##
## Uses a callback as a criteron to determine
## which entities should be returned.[br]
##
## [codeblock]
## var entity = ECSManager.find_nearest_entity_with_component(
##     "HealthComponent",
##     Vector3(randf(),randf(),randf()),
##     func(e: ECSEntity): return e.get_health() > 0,
##     11.25
## )
## [/codeblock][br]
##
## [param component_name] The name of the component the entity must have.[br]
## [param from] The point in space from which to start Searching.[br]
## [param filter] Callback function to filter entities by. Optional.[br]
## [param max_distance] Search radius.[br]
## Returns an [ECSEntity] if found, [code]null[/code] otherwise.
func find_nearest_entity_with_component(
	component_name: String,
	from: Vector3,
	filter: Callable = func(_e: ECSComponent): return true,
	max_distance: float = INF
) -> ECSEntity:
	var candidates = find_entities_with_component(component_name, filter)

	var nearest: ECSEntity = null
	var nearest_dist: float = INF

	for entity in candidates:
		var dist := from.distance_to(entity.global_position)
		if dist < nearest_dist and (dist < max_distance or is_equal_approx(dist, max_distance)):
			nearest_dist = dist
			nearest = entity

	return nearest


## Finds all entities within a radius.[br][br]
##
## Uses a callback as a criteron to determine
## which entities should be returned, if any.[br]
##
## [codeblock]
## var entity = ECSManager.find_entities_in_radius(
##     Vector3(randf(),randf(),randf()),
##     11.25,
##     func(e: ECSEntity): return e.get_health() > 0
## )
## [/codeblock][br]
##
## [param position] Point in space from which to start searching.[br]
## [param radius] Search radius.[br]
## [param filter] Callback function to filter entities by. Optional.[br]
## Returns an array of [ECSEntity].
func find_entities_in_radius(
	position: Vector3,
	radius: float,
	filter: Callable = func(_e): return true
) -> Array[ECSEntity]:
	var results: Array[ECSEntity] = []

	for entity in entities.values():
		var dist = position.distance_to(entity.global_position)
		if (dist < radius or is_equal_approx(dist, radius)) and filter.call(entity):
			results.append(entity)

	return results


## Gets all registered entities
func get_all_entities() -> Array[ECSEntity]:
	return entities.values() as Array[ECSEntity]


## Clears all registered entities
## Useful for scene transitions
func clear_all() -> void:
	entities.clear()
	entities_by_component.clear()
