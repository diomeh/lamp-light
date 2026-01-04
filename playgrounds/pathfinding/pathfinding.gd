extends Node3D

@onready var pcam: PhantomCamera3D = $PhantomCamera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for light in get_tree().get_nodes_in_group("lights"):
		WorldState.append_value("light_positions", light.global_position)
		WorldState.set_value("lights_available", true)

	pcam.look_at_mode = PhantomCamera3D.LookAtMode.GROUP

	for actor in get_tree().get_nodes_in_group("actors"):
		pcam.append_look_at_target(actor)

		# Configure the character's GOAP brain
		var goap: GOAPAgent = actor.goap
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
