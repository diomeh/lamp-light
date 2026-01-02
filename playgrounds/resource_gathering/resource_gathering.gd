## Setup script for Resource Gathering Playground
extends Node3D

@onready var pcam: PhantomCamera3D = $PhantomCamera3D

## How many gatherer agents to spawn
@export var num_gatherers: int = 3

## How many resource nodes to spawn
@export var num_resources: int = 30

## Preload or reference Actor scene
@export var gatherer_scene: PackedScene

## Preload Resource scene
@export var resource_scene: PackedScene

## Preload InventoryComponent scene
@export var inv_comp_scene: PackedScene

## Shared world state for all agents
var world_state: GOAPState


func _ready() -> void:
	# Initialize shared world state
	world_state = GOAPState.new()

	# Spawn entities
	_spawn_resources()
	_spawn_gatherers()

	print("=== Resource Gathering Playground Started ===")
	print("Gatherers: %d" % num_gatherers)
	print("Resources: %d" % num_resources)
	print("Storage: 1")


## Spawns resource nodes around the map
## Spawns resource nodes around the map
func _spawn_resources() -> void:
	for i in range(num_resources):
		var instance = resource_scene.instantiate() as StaticBody3D

		# Add to tree FIRST
		add_child(instance)

		# THEN set position
		var angle = randf() * TAU
		var radius = randf_range(10, 20)
		var pos = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		instance.global_position = pos

		var resource_comp = instance.get_node("ECSEntity").get_component("ResourceComponent") as ResourceComponent
		print("Spawned %s resource at %v with %d units" % [
			resource_comp.resource_type if resource_comp else 'unknown',
			pos,
			resource_comp.amount if resource_comp else 0
		])


## Spawns gatherer agents
func _spawn_gatherers() -> void:
	for i in range(num_gatherers):
		var gatherer: Actor

		gatherer = gatherer_scene.instantiate() as Actor

		gatherer.name = "Gatherer_%d" % i
		add_child(gatherer)

		# Random starting position near storage
		var angle = (float(i) / num_gatherers) * TAU
		var pos = Vector3(cos(angle) * 5, 0, sin(angle) * 5)
		gatherer.global_position = pos

		# Setup GOAP agent
		var goap_agent = gatherer.goap
		if goap_agent:
			_setup_goap_agent(goap_agent, i)

		var inv_comp = inv_comp_scene.instantiate() as InventoryComponent
		gatherer.entity.add_component(inv_comp)
		pcam.append_look_at_target(gatherer)

		print("Spawned gatherer %d at %v" % [i, pos])

## Configures GOAP agent with actions and goals
func _setup_goap_agent(agent: GOAPAgent, agent_id: int) -> void:
	agent.world_state = world_state

	agent.actions = [
		MoveToResourceAction.new(),
		GatherResourceAction.new(),
		MoveToStorageAction.new(),
		StoreResourceAction.new()
	]

	agent.goals = [
		GatherAndStoreGoal.new()
	]

	agent.blackboard.set_value("agent_id", agent_id)
	agent.blackboard.set_value("has_resource", false)
	agent.blackboard.set_value("resource_stored", false)
	agent.blackboard.set_value("near_resource", false)
	agent.blackboard.set_value("near_storage", false)
