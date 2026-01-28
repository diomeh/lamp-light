## Central debug manager for GOAP system.
##
## Autoload singleton that coordinates all debug tools and manages agent subscriptions.[br]
## Automatically subscribes to all GOAP signals and aggregates events across agents.[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## # Add to project.godot autoload:
## # GOAPDebugManager="*res://systems/goap/debug/goap_debug_autoload.gd"
##
## # Access from anywhere:
## GOAPDebugManager.get_all_agents()
## GOAPDebugManager.get_events_for_agent(agent, 100)
## GOAPDebugManager.show_debug_overlay()
## [/codeblock]
##
## See also: [GOAPAgent], [DebugEvent]
extends Node

## Emitted when a debug event is recorded.[br]
## [param event] The recorded event.
signal debug_event_recorded(event: DebugEvent)

## Emitted when an agent is registered.[br]
## [param agent] The registered agent.
signal agent_registered(agent: GOAPAgent)

## Emitted when an agent is unregistered.[br]
## [param agent] The unregistered agent.
signal agent_unregistered(agent: GOAPAgent)

## Enable debug tools in production builds.
const DEBUG_ENABLED: bool = true  # Set to OS.is_debug_build() for production

## Maximum events to store in buffer.
@export var max_events: int = 5000

## Event retention time in seconds (0 = unlimited).
@export var event_retention_time: float = 300.0  # 5 minutes

## Registered agents.
var _agents: Array[GOAPAgent] = []

## Event buffer (ring buffer).
var _events: Array[DebugEvent] = []

## Event buffer head index.
var _event_head: int = 0

## Whether recording is enabled.
var _recording_enabled: bool = true

## Debug overlay instance.
var _debug_overlay: Control = null


func _ready() -> void:
	if not DEBUG_ENABLED:
		set_process(false)
		return

	# Listen for agents registering with orchestrator
	if GOAPOrchestrator:
		GOAPOrchestrator.agent_registered.connect(_on_orchestrator_agent_registered)

		# Register any existing agents
		for agent in GOAPOrchestrator.get_agents():
			register_agent(agent)

	print("[GOAPDebug] Debug manager initialized")


func _process(_delta: float) -> void:
	if not DEBUG_ENABLED:
		return

	# Prune old events if retention time is set
	if event_retention_time > 0.0:
		_prune_old_events()


## Registers an agent for debug monitoring.[br][br]
##
## Automatically connects to all agent signals.[br][br]
##
## [param agent] Agent to register.
func register_agent(agent: GOAPAgent) -> void:
	if agent in _agents:
		return

	_agents.append(agent)

	# Connect to agent signals
	agent.goal_selected.connect(_on_goal_selected.bind(agent))
	agent.plan_created.connect(_on_plan_created.bind(agent))
	agent.plan_failed.connect(_on_plan_failed.bind(agent))
	agent.plan_completed.connect(_on_plan_completed.bind(agent))
	agent.plan_aborted.connect(_on_plan_aborted.bind(agent))
	agent.plan_metrics.connect(_on_plan_metrics.bind(agent))
	agent.plan_debug.connect(_on_plan_debug.bind(agent))

	# Connect to executor signals
	agent._executor.action_started.connect(_on_action_started.bind(agent))
	agent._executor.action_ended.connect(_on_action_ended.bind(agent))

	# Connect to blackboard signals
	agent.blackboard.state_changed.connect(_on_state_changed.bind(agent))

	agent_registered.emit(agent)
	print("[GOAPDebug] Registered agent: ", agent.name)


## Unregisters an agent from debug monitoring.[br][br]
##
## [param agent] Agent to unregister.
func unregister_agent(agent: GOAPAgent) -> void:
	if agent not in _agents:
		return

	# Disconnect all signals
	if agent.goal_selected.is_connected(_on_goal_selected):
		agent.goal_selected.disconnect(_on_goal_selected)
	if agent.plan_created.is_connected(_on_plan_created):
		agent.plan_created.disconnect(_on_plan_created)
	if agent.plan_failed.is_connected(_on_plan_failed):
		agent.plan_failed.disconnect(_on_plan_failed)
	if agent.plan_completed.is_connected(_on_plan_completed):
		agent.plan_completed.disconnect(_on_plan_completed)
	if agent.plan_aborted.is_connected(_on_plan_aborted):
		agent.plan_aborted.disconnect(_on_plan_aborted)
	if agent.plan_metrics.is_connected(_on_plan_metrics):
		agent.plan_metrics.disconnect(_on_plan_metrics)
	if agent.plan_debug.is_connected(_on_plan_debug):
		agent.plan_debug.disconnect(_on_plan_debug)

	if agent._executor.action_started.is_connected(_on_action_started):
		agent._executor.action_started.disconnect(_on_action_started)
	if agent._executor.action_ended.is_connected(_on_action_ended):
		agent._executor.action_ended.disconnect(_on_action_ended)

	if agent.blackboard.state_changed.is_connected(_on_state_changed):
		agent.blackboard.state_changed.disconnect(_on_state_changed)

	_agents.erase(agent)
	agent_unregistered.emit(agent)
	print("[GOAPDebug] Unregistered agent: ", agent.name)


## Returns all registered agents.[br][br]
##
## Returns array of agents.
func get_all_agents() -> Array[GOAPAgent]:
	return _agents.duplicate()


## Returns events for specific agent.[br][br]
##
## [param agent] Agent to get events for.[br]
## [param limit] Maximum number of events to return (0 = all).[br]
## [br]
## Returns array of events.
func get_events_for_agent(agent: GOAPAgent, limit: int = 100) -> Array[DebugEvent]:
	var result: Array[DebugEvent] = []
	for event in _events:
		if event.agent == agent:
			result.append(event)
			if limit > 0 and result.size() >= limit:
				break
	return result


## Returns all events.[br][br]
##
## [param limit] Maximum number of events to return (0 = all).[br]
## [br]
## Returns array of events.
func get_all_events(limit: int = 0) -> Array[DebugEvent]:
	if limit > 0 and limit < _events.size():
		return _events.slice(-limit)
	return _events.duplicate()


## Clears all stored events.
func clear_events() -> void:
	_events.clear()
	_event_head = 0
	print("[GOAPDebug] Events cleared")


## Sets whether recording is enabled.[br][br]
##
## [param enabled] Enable/disable recording.
func set_recording_enabled(enabled: bool) -> void:
	_recording_enabled = enabled
	print("[GOAPDebug] Recording ", "enabled" if enabled else "disabled")


## Returns whether recording is enabled.[br][br]
##
## Returns [code]true[/code] if recording.
func is_recording_enabled() -> bool:
	return _recording_enabled


## Exports events to JSON file.[br][br]
##
## [param path] File path to write to.[br]
## [br]
## Returns Error code.
func export_events_to_json(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()

	var export_data := {
		"export_time": Time.get_datetime_string_from_system(),
		"event_count": _events.size(),
		"agent_count": _agents.size(),
		"events": []
	}

	for event in _events:
		export_data["events"].append(event.to_dict())

	file.store_string(JSON.stringify(export_data, "\t"))
	file.close()

	print("[GOAPDebug] Exported ", _events.size(), " events to ", path)
	return OK


## Shows the debug overlay UI.
func show_debug_overlay() -> void:
	if not _debug_overlay:
		_load_debug_overlay()

	if _debug_overlay:
		_debug_overlay.show()


## Hides the debug overlay UI.
func hide_debug_overlay() -> void:
	if _debug_overlay:
		_debug_overlay.hide()


## Toggles the debug overlay UI.
func toggle_debug_overlay() -> void:
	if not _debug_overlay:
		_load_debug_overlay()

	if _debug_overlay:
		_debug_overlay.visible = not _debug_overlay.visible


## Records a debug event.[br][br]
##
## [param event] Event to record.
func _record_event(event: DebugEvent) -> void:
	if not _recording_enabled:
		return

	# Ring buffer behavior
	if _events.size() < max_events:
		_events.append(event)
	else:
		_events[_event_head] = event
		_event_head = (_event_head + 1) % max_events

	debug_event_recorded.emit(event)


## Prunes events older than retention time.
func _prune_old_events() -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var cutoff_time := current_time - event_retention_time

	var pruned := 0
	for i in range(_events.size() - 1, -1, -1):
		if _events[i].timestamp < cutoff_time:
			_events.remove_at(i)
			pruned += 1

	if pruned > 0:
		_event_head = 0  # Reset ring buffer head after pruning


## Loads debug overlay scene.
func _load_debug_overlay() -> void:
	var overlay_scene := load("res://systems/goap/debug/ui/goap_debug_overlay.tscn")
	if overlay_scene:
		_debug_overlay = overlay_scene.instantiate()
		get_tree().root.add_child(_debug_overlay)
		print("[GOAPDebug] Debug overlay loaded")
	else:
		push_error("[GOAPDebug] Failed to load debug overlay scene")


## Signal handlers

func _on_orchestrator_agent_registered(agent: GOAPAgent) -> void:
	register_agent(agent)


func _on_goal_selected(goal: GOAPGoal, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.GOAL_SELECTED, {
		"goal": goal,
		"priority": goal.get_priority(agent.blackboard.to_ref())
	})
	_record_event(event)


func _on_plan_created(goal: GOAPGoal, plan: Array[GOAPAction], agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.PLAN_CREATED, {
		"goal": goal,
		"plan": plan,
		"plan_size": plan.size()
	})
	_record_event(event)


func _on_plan_failed(goal: GOAPGoal, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.PLAN_FAILED, {
		"goal": goal
	})
	_record_event(event)


func _on_plan_completed(goal: GOAPGoal, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.PLAN_COMPLETED, {
		"goal": goal
	})
	_record_event(event)


func _on_plan_aborted(goal: GOAPGoal, action: GOAPAction, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.PLAN_ABORTED, {
		"goal": goal,
		"action": action
	})
	_record_event(event)


func _on_plan_metrics(goal: GOAPGoal, plan: Array[GOAPAction], planning_time_ms: float, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.METRIC_RECORDED, {
		"goal": goal,
		"plan": plan,
		"planning_time_ms": planning_time_ms,
		"metric_type": "planning_time"
	})
	_record_event(event)


func _on_plan_debug(goal: GOAPGoal, failure_reason: String, agent: GOAPAgent) -> void:
	# This is already captured in plan_failed, but we can add the reason
	var event := DebugEvent.create(agent, DebugEvent.EventType.PLAN_FAILED, {
		"goal": goal,
		"reason": failure_reason
	})
	_record_event(event)


func _on_action_started(action: GOAPAction, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.ACTION_STARTED, {
		"action": action
	})
	_record_event(event)


func _on_action_ended(action: GOAPAction, result: GOAPAction.ExecResult, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.ACTION_ENDED, {
		"action": action,
		"result": result
	})
	_record_event(event)


func _on_state_changed(key: StringName, new_value: Variant, old_value: Variant, agent: GOAPAgent) -> void:
	var event := DebugEvent.create(agent, DebugEvent.EventType.STATE_CHANGED, {
		"key": key,
		"new_value": new_value,
		"old_value": old_value
	})
	_record_event(event)
