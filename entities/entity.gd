class_name Entity
extends RigidBody3D

## The character's GOAP brain (May be null if not AI controlled)
@onready var goap: GOAPAgent = %Agent

@onready var _mesh: MeshInstance3D = %MeshInstance3D

## This entity's mesh color
@export var color: Color

## Movement speed
@export var move_speed: float = 5.0

## Systems which can control this entity
enum ControlMode { PLAYER, AI }

## Current system controlling this entity
@export var control_mode: ControlMode = ControlMode.AI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if goap:
		goap.blackboard.set_value("move_speed", move_speed)

	if color:
		_mesh["mesh"]["material"]["albedo_color"] = color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _physics_process(_delta: float) -> void:
	match control_mode:
		ControlMode.PLAYER:
			_handle_player_input()
		ControlMode.AI:
			pass  # GOAP handles this via actions

## Rudimentary character controls
func _handle_player_input() -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction:
		linear_velocity = direction * move_speed


## Movement function that can be called by control systems
func move_toward(target: Vector3, speed: float) -> void:
	var direction := (target - global_position).normalized()
	linear_velocity = Vector3(direction.x * speed, linear_velocity.y, direction.z * speed)


## Stop all movement
func stop_moving() -> void:
	linear_velocity = Vector3.ZERO


## Make character look at a position
func look_toward(target: Vector3) -> void:
	var direction := target - global_position
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)
