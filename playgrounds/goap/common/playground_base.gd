## Base scene for GOAP playground scenarios.
##
## Provides common functionality for all playground implementations:[br]
## - Standard input handling (pause, reset, debug toggle, time scale)[br]
## - Debug overlay management[br]
## - Time control[br]
## - Agent selection and inspection[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## extends PlaygroundBase
##
## func _ready() -> void:
##     super._ready()  # Call parent setup
##     _spawn_agents()
##     _setup_environment()
##
## func _on_reset_pressed() -> void:
##     # Custom reset logic
##     pass
## [/codeblock]
class_name PlaygroundBase
extends Node2D

## Emitted when debug overlay is toggled.
signal debug_toggled(visible: bool)

## Emitted when simulation is paused/unpaused.
signal paused_toggled(paused: bool)

## Emitted when time scale changes.
signal time_scale_changed(scale: float)

## Emitted when an agent is selected for inspection.
signal agent_selected(agent: GOAPAgent)

## Reference to debug overlay UI.
var debug_overlay: DebugOverlay

## All agents in the scene.
var agents: Array[GOAPAgent] = []

## Currently selected agent for inspection.
var selected_agent: GOAPAgent = null

## Simulation paused state.
var is_paused: bool = false:
	set(value):
		is_paused = value
		Engine.time_scale = 0.0 if is_paused else current_time_scale
		paused_toggled.emit(is_paused)

## Current time scale multiplier.
var current_time_scale: float = 1.0:
	set(value):
		current_time_scale = clampf(value, 0.1, 10.0)
		if not is_paused:
			Engine.time_scale = current_time_scale
		time_scale_changed.emit(current_time_scale)


func _ready() -> void:
	_setup_debug_overlay()
	_setup_input_actions()


func _unhandled_input(event: InputEvent) -> void:
	# F1 - Toggle debug overlay
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_toggle_debug()
		get_viewport().set_input_as_handled()

	# Space - Pause/Resume
	if event.is_action_pressed("ui_select"):  # Space
		is_paused = !is_paused
		get_viewport().set_input_as_handled()

	# R - Reset
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_reset_scenario()
		get_viewport().set_input_as_handled()

	# Time scale controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				current_time_scale = 1.0
				get_viewport().set_input_as_handled()
			KEY_2:
				current_time_scale = 2.0
				get_viewport().set_input_as_handled()
			KEY_5:
				current_time_scale = 5.0
				get_viewport().set_input_as_handled()
			KEY_X:
				current_time_scale = 10.0
				get_viewport().set_input_as_handled()

	# Mouse click - Agent selection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_agent_click(event.position)


## Sets up the debug overlay UI component.
func _setup_debug_overlay() -> void:
	debug_overlay = DebugOverlay.new()
	debug_overlay.visible = false
	add_child(debug_overlay)


## Ensures required input actions exist.
func _setup_input_actions() -> void:
	# Input actions are handled via raw key events for maximum compatibility
	pass


## Toggles debug overlay visibility.
func _toggle_debug() -> void:
	if debug_overlay:
		debug_overlay.visible = !debug_overlay.visible
		debug_toggled.emit(debug_overlay.visible)


## Handles agent selection on mouse click.
## Override to customize selection behavior.
func _handle_agent_click(click_pos: Vector2) -> void:
	var closest_agent: GOAPAgent = null
	var closest_distance: float = 50.0  # Max selection distance

	for agent in agents:
		if not is_instance_valid(agent):
			continue

		var agent_pos := Vector2.ZERO
		if agent.actor is Node2D:
			agent_pos = agent.actor.global_position

		var distance := click_pos.distance_to(agent_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_agent = agent

	if closest_agent != selected_agent:
		selected_agent = closest_agent
		agent_selected.emit(selected_agent)

		if debug_overlay:
			debug_overlay.set_inspected_agent(selected_agent)


## Resets scenario to initial state.
## Override in derived classes for scenario-specific reset logic.
func _reset_scenario() -> void:
	selected_agent = null
	if debug_overlay:
		debug_overlay.set_inspected_agent(null)


## Registers an agent with the playground.
func register_agent(agent: GOAPAgent) -> void:
	if agent and agent not in agents:
		agents.append(agent)


## Unregisters an agent from the playground.
func unregister_agent(agent: GOAPAgent) -> void:
	agents.erase(agent)


## Updates debug overlay with current metrics.
## Call this in _process if you want live metric updates.
func update_debug_metrics(metrics: Dictionary) -> void:
	if debug_overlay:
		debug_overlay.update_metrics(metrics)
