## Crafting station node.
##
## Represents a physical crafting station in the factory.[br]
## Can be reserved by crafters to prevent conflicts.
class_name CraftingStation
extends Node2D

## Station type/name.
@export var station_type: StringName = &"furnace"

## Processing time in seconds.
@export var processing_time: float = 3.0

## Currently occupied by crafter.
var occupied_by: CrafterAgent = null

## Station position marker.
var _marker: Node2D


func _ready() -> void:
	_create_visual()


## Creates visual representation.
func _create_visual() -> void:
	_marker = Node2D.new()
	_marker.name = "Marker"
	add_child(_marker)
	_marker.queue_redraw()
	_marker.draw.connect(_on_marker_draw)


func _on_marker_draw() -> void:
	if not _marker:
		return

	# Draw station as rectangle
	var color := Color(0.4, 0.4, 0.6, 0.7) if not occupied_by else Color(0.6, 0.6, 0.2, 0.9)
	var rect := Rect2(-20, -20, 40, 40)
	_marker.draw_rect(rect, color)
	_marker.draw_rect(rect, Color.WHITE, false, 2.0)

	# Draw station label
	var font := ThemeDB.fallback_font
	_marker.draw_string(font, Vector2(0, -25), str(station_type), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)


## Checks if station is available.
func is_available() -> bool:
	return occupied_by == null


## Reserves station for crafter.
func reserve(crafter: CrafterAgent) -> bool:
	if occupied_by:
		return false
	occupied_by = crafter
	_marker.queue_redraw()
	return true


## Releases station.
func release() -> void:
	occupied_by = null
	_marker.queue_redraw()


## Gets station center position.
func get_work_position() -> Vector2:
	return global_position
