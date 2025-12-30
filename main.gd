extends Node3D

@onready var entity: Entity = $Entity
@onready var light: OmniLight3D = $OmniLight3D

@export var world_state: GOAPState

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up world state
	if not world_state:
		push_error("Main scene requires a GOAP world state.")
		return

	world_state.set_value("light_positions", [light.global_position])
	world_state.set_value("lights_available", true)

	# Configure the character's GOAP brain
	var goap := entity.goap
	goap.world_state = world_state
	goap.blackboard.set_value("has_target", false)
	goap.blackboard.set_value("at_target", false)
	goap.goals = [ReachTarget.new()]
	goap.actions = [
		SelectTarget.new(),
		MoveTo.new()
	]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
