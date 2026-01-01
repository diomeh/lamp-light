## Base class for all entity components.
##
## Components define specific behaviors and properties for entities.[br][br]
##
## Usage:
## [codeblock]
## class_name MyComponent
## extends ECSComponent
##
## func _ready() -> void:
##     super._ready()
##     # Your initialization
## [/codeblock]
class_name ECSComponent
extends Node

## The name of this component.
@export var component_name: String = ""

## Reference to the entity this component belongs to.[br]
## Set automatically by [ECSComponent] when component is registered
var entity: ECSEntity = null


func _ready() -> void:
	# Wait one frame to ensure entity reference is set
	await get_tree().process_frame

	if not entity:
		entity = get_parent() as ECSEntity
		assert(entity != null, "ECSComponent must be a child of an Entity node!")

	_on_component_ready()


## Override this in derived classes for component-specific initialization[br]
## Called after entity reference is guaranteed to be set
func _on_component_ready() -> void:
	pass
