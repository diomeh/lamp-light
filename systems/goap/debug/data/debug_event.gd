## Debug event data structure for GOAP system monitoring.
##
## Represents a single event in the GOAP system lifecycle.[br]
## Events are emitted by agents and executors and aggregated by [GOAPDebugAutoload].[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var event := DebugEvent.new()
## event.timestamp = Time.get_ticks_msec() / 1000.0
## event.agent = agent
## event.event_type = DebugEvent.EventType.GOAL_SELECTED
## event.data = {"goal": goal, "priority": priority}
## [/codeblock]
class_name DebugEvent
extends Resource

## Event types corresponding to GOAP signals.
enum EventType {
	GOAL_SELECTED,      ## Agent selected a new goal
	PLAN_CREATED,       ## Plan generated successfully
	PLAN_FAILED,        ## Planning failed (no valid plan)
	PLAN_COMPLETED,     ## Plan executed successfully
	PLAN_ABORTED,       ## Plan aborted due to action failure
	ACTION_STARTED,     ## Action began executing
	ACTION_ENDED,       ## Action finished (success/failure)
	STATE_CHANGED,      ## Blackboard value changed
	METRIC_RECORDED,    ## Performance metric recorded
}

## Timestamp in seconds (from game start).
var timestamp: float = 0.0

## Agent that generated this event.
var agent: GOAPAgent = null

## Type of event.
var event_type: EventType = EventType.GOAL_SELECTED

## Additional event data.[br]
## Contents vary by event type:[br]
## - GOAL_SELECTED: [code]{"goal": GOAPGoal, "priority": float}[/code][br]
## - PLAN_CREATED: [code]{"goal": GOAPGoal, "plan": Array[GOAPAction], "planning_time_ms": float}[/code][br]
## - PLAN_FAILED: [code]{"goal": GOAPGoal, "reason": String}[/code][br]
## - ACTION_STARTED: [code]{"action": GOAPAction}[/code][br]
## - ACTION_ENDED: [code]{"action": GOAPAction, "result": GOAPAction.ExecResult}[/code][br]
## - STATE_CHANGED: [code]{"key": StringName, "new_value": Variant, "old_value": Variant}[/code]
var data: Dictionary = {}


## Creates event from agent signal data.[br][br]
##
## [param p_agent] Agent that emitted the signal.[br]
## [param p_event_type] Type of event.[br]
## [param p_data] Event-specific data.[br]
## [br]
## Returns new DebugEvent instance.
static func create(p_agent: GOAPAgent, p_event_type: EventType, p_data: Dictionary) -> DebugEvent:
	var event := DebugEvent.new()
	event.timestamp = Time.get_ticks_msec() / 1000.0
	event.agent = p_agent
	event.event_type = p_event_type
	event.data = p_data
	return event


## Converts event to dictionary for serialization.[br][br]
##
## Returns dictionary representation.
func to_dict() -> Dictionary:
	return {
		"timestamp": timestamp,
		"agent_name": agent.get_name(),
		"event_type": EventType.keys()[event_type],
		"data": _sanitize_data(data)
	}


## Sanitizes data for JSON export (removes non-serializable objects).[br][br]
##
## [param dict] Dictionary to sanitize.[br]
## [br]
## Returns sanitized dictionary.
func _sanitize_data(dict: Dictionary) -> Dictionary:
	var result := {}
	for key in dict:
		var value = dict[key]
		if value is GOAPGoal:
			result[key] = {"goal_name": value.goal_name, "priority": value.priority}
		elif value is GOAPAction:
			result[key] = {"action_name": value.action_name, "cost": value.cost}
		elif value is Array:
			result[key] = _sanitize_array(value)
		elif value is Dictionary:
			result[key] = _sanitize_data(value)
		elif value is String or value is float or value is int or value is bool:
			result[key] = value
		else:
			result[key] = str(value)
	return result


## Sanitizes array for JSON export.[br][br]
##
## [param arr] Array to sanitize.[br]
## [br]
## Returns sanitized array.
func _sanitize_array(arr: Array) -> Array:
	var result := []
	for item in arr:
		if item is GOAPAction:
			result.append({"action_name": item.action_name, "cost": item.cost})
		elif item is Dictionary:
			result.append(_sanitize_data(item))
		else:
			result.append(str(item))
	return result
