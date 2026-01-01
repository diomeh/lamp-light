## Base class for all entities in the game world.
##
## Entities are game objects that can have components attached to define their behavior.
class_name ECSEntity
extends Node

## Unique identifier for this entity.
@export var entity_id: String = ""

## Optional metadata for flexible data storage.
@export var metadata: Dictionary[String, Variant] = {}

## Components attached to this entity.
var components: Dictionary[String, ECSComponent] = {}


func _ready() -> void:
	# Generate ID if not set
	if entity_id.is_empty():
		entity_id = _generate_id()

	ECSManager.register_entity(self)

	# Initialize all child components
	_setup_components()


func _exit_tree() -> void:
	ECSManager.unregister_entity(self)


## Automatically finds and registers all ECSComponent children
func _setup_components() -> void:
	for child in get_children():
		if child is ECSComponent:
			_register_component(child)


## Registers a component with this entity
func _register_component(component: ECSComponent) -> void:
	assert(not component.component_name.is_empty(), "ECSComponent name cannot be empty")

	components[component.component_name] = component
	component.entity = self


## Adds a component to this entity at runtime
func add_component(component: ECSComponent) -> void:
	add_child(component)
	_register_component(component)


## Removes a component from this entity
func remove_component(component_name: String) -> void:
	if not components.has(component_name): return

	var component = components[component_name]
	components.erase(component_name)
	component.queue_free()


## Gets a component by its name
## Returns null if component doesn't exist
func get_component(component_name: String) -> ECSComponent:
	return components.get(component_name)


## Checks if this entity has a specific component
func has_component(component_name: String) -> bool:
	return components.has(component_name)


## Gets all components of this entity
func get_all_components() -> Array[ECSComponent]:
	return components.values() as Array[ECSComponent]


## Generates a unique ID for this entity
func _generate_id() -> String:
	return "%s_%d" % [name, get_instance_id()]
