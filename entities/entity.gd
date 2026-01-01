## Base entity class with AI and player control support.
##
## Provides movement API used by GOAP actions and optional player controls.
## Contains a [GOAPAgent] child for AI behavior when in [enum ControlMode.AI].
##
## [b]Movement API:[/b]
## - [method move_toward]: Navigate to position
## - [method stop_moving]: Halt movement
## - [method look_toward]: Face a position
##
## @see [GOAPAgent]
## @see [GOAPAction]
class_name Entity
extends CharacterBody3D

## GOAP brain for AI control. May be [code]null[/code] for non-AI entities.
@onready var goap: GOAPAgent = %GOAPAgent

@onready var _nav_agent: NavigationAgent3D = %NavigationAgent3D
@onready var _mesh: MeshInstance3D = %MeshInstance3D

## Visual color applied to entity mesh.
@export var color: Color

## Base movement speed in units/second.
@export var move_speed: float = 10.0

## Control systems that can drive this entity.
enum ControlMode {
	PLAYER, ## Direct player input
	AI ## GOAP-driven behavior
}

## Active control system.
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
			pass # GOAP handles this via actions

## Processes player input for manual control.
##
## Uses input actions: [code]left[/code], [code]right[/code], [code]forward[/code], [code]back[/code].
func _handle_player_input() -> void:
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()

	if direction:
		velocity = direction * move_speed
		move_and_slide()


## Moves entity toward target using navigation.
##
## Called by GOAP actions like [MoveTo]. Updates navigation path
## only when target changes.
##
## [param target] World position to move toward.
## [param speed] Movement speed in units/second.
func move_toward(target: Vector3, speed: float) -> void:
	# Prevent path from being recalculated every frame
	if not _nav_agent.target_position.is_equal_approx(target):
		_nav_agent.target_position = target

	var next = _nav_agent.get_next_path_position()
	var direction := (next - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()


## Halts all movement immediately.
func stop_moving() -> void:
	velocity = Vector3.ZERO


## Rotates entity to face target position.
##
## [param target] World position to look at.
func look_toward(target: Vector3) -> void:
	var direction := target - global_position
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)
