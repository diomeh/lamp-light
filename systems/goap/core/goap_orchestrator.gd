## Central scheduler for GOAP agent thinking.
##
## Distributes agent planning across frames to prevent performance spikes.[br]
## Agents register automatically and are scheduled via round-robin with budget control.[br][br]
##
## [b]Architecture:[/b][br]
## - Agents in IDLE/PLANNING states are scheduled by orchestrator[br]
## - Agents in PERFORMING state self-drive (need every-frame updates)[br]
## - Budget prevents frame spikes from many agents planning simultaneously[br][br]
##
## [b]Usage:[/b][br]
## Autoload this script in Project Settings. Agents register automatically.[br]
## [codeblock]
## # Adjust settings if needed:
## GOAPOrchestrator.think_budget_ms = 6.0
## GOAPOrchestrator.min_think_interval = 0.5
## [/codeblock]
## [br]
## See also: [GOAPAgent], [GOAPPlanner]
extends Node

## Emitted when a new agent registers.[br]
## [param agent] The agent that registered.
signal agent_registered(agent: GOAPAgent)

## Maximum milliseconds per frame for agent thinking.[br]
## Prevents frame spikes when many agents need planning.
@export var think_budget_ms: float = 4.0

## Minimum seconds between an agent's think cycles.[br]
## Prevents single agent from monopolizing budget.
@export var min_think_interval: float = 0.3

## Registered agents.
var _agents: Array[GOAPAgent] = []

## Last think timestamp per agent (seconds).
var _agent_last_think: Dictionary = {}  # GOAPAgent -> float

## Current round-robin index.
var _current_index: int = 0


func _physics_process(_delta: float) -> void:
	_process_agents()


## Registers an agent for orchestrated thinking.[br][br]
##
## Called automatically by GOAPAgent._ready().[br]
## Duplicate registration is ignored.[br][br]
##
## [param agent] Agent to register.
func register_agent(agent: GOAPAgent) -> void:
	if agent in _agents:
		return

	_agents.append(agent)
	_agent_last_think[agent] = -min_think_interval  # Allow immediate first think
	agent_registered.emit(agent)


## Unregisters an agent from orchestration.[br][br]
##
## Called automatically by GOAPAgent._exit_tree().[br][br]
##
## [param agent] Agent to unregister.
func unregister_agent(agent: GOAPAgent) -> void:
	_agents.erase(agent)
	_agent_last_think.erase(agent)


## Returns number of registered agents.
func get_agent_count() -> int:
	return _agents.size()


## Returns registered agents array (read-only copy).
func get_agents() -> Array[GOAPAgent]:
	return _agents.duplicate()


## Processes agents within frame budget.
func _process_agents() -> void:
	if _agents.is_empty():
		return

	var start_time := Time.get_ticks_usec()
	var budget_usec := think_budget_ms * 1000.0
	var current_time := Time.get_ticks_msec() / 1000.0
	var agents_checked := 0

	while agents_checked < _agents.size():
		var elapsed := Time.get_ticks_usec() - start_time
		if elapsed >= budget_usec:
			break

		_current_index = (_current_index + 1) % _agents.size()
		var agent := _agents[_current_index]
		agents_checked += 1

		var last_think: float = _agent_last_think.get(agent, 0.0)
		var agent_priority: float = agent.get_think_priority()
		var adjusted_interval: float = min_think_interval / max(agent_priority, 0.1)
		if current_time - last_think < adjusted_interval:
			continue

		if not agent.needs_thinking():
			continue

		var plan_start := Time.get_ticks_usec()
		agent.think()
		var plan_elapsed := Time.get_ticks_usec() - plan_start
		_agent_last_think[agent] = current_time

		if plan_elapsed > budget_usec * 0.8:
			break


## Clears all registered agents.[br][br]
##
## Useful for scene transitions or testing.
func clear() -> void:
	_agents.clear()
	_agent_last_think.clear()
	_current_index = 0
