extends Node3D

@onready var pcam: PhantomCamera3D = $PhantomCamera3D

@export var world_state: GOAPState

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up world state
	if not world_state:
		push_error("Main scene requires a GOAP world state.")
		return

	for light in get_tree().get_nodes_in_group("lights"):
		world_state.append_value("light_positions", light.global_position)
		world_state.set_value("lights_available", true)

	pcam.look_at_mode = PhantomCamera3D.LookAtMode.GROUP

	for entity in get_tree().get_nodes_in_group("entities"):
		pcam.append_look_at_target(entity)

		# Configure the character's GOAP brain
		var goap : GOAPAgent = entity.goap
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
