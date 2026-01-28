## Timeline entry for execution timeline visualization.
##
## Represents a time-bound activity (goal, action, or plan) in the timeline.[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var entry := TimelineEntry.new()
## entry.start_time = 5.0
## entry.end_time = 8.0
## entry.entry_type = "action"
## entry.name = "WalkToWaypoint"
## entry.status = "success"
## [/codeblock]
class_name TimelineEntry
extends Resource

## Start time in seconds.
var start_time: float = 0.0

## End time in seconds (0.0 if still running).
var end_time: float = 0.0

## Type of entry: "goal", "action", or "plan".
var entry_type: String = ""

## Display name (goal/action name).
var name: String = ""

## Status: "success", "failure", "aborted", "running".
var status: String = "running"

## Additional metadata (action details, plan info, etc.).
var metadata: Dictionary = {}


## Returns duration in seconds.[br][br]
##
## Returns duration (0.0 if still running).
func get_duration() -> float:
	if end_time == 0.0:
		return Time.get_ticks_msec() / 1000.0 - start_time
	return end_time - start_time


## Checks if entry is currently running.[br][br]
##
## Returns [code]true[/code] if running.
func is_running() -> bool:
	return end_time == 0.0 and status == "running"


## Converts to dictionary for serialization.[br][br]
##
## Returns dictionary representation.
func to_dict() -> Dictionary:
	return {
		"start_time": start_time,
		"end_time": end_time,
		"entry_type": entry_type,
		"name": name,
		"status": status,
		"duration": get_duration(),
		"metadata": metadata
	}
