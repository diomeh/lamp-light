## Event logging utility for GOAP debug system.
##
## Provides file and console logging with rotation and filtering.[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## var logger := GOAPEventLogger.new()
## logger.set_log_file_path("user://goap_logs/session.log")
## logger.log_event(event, GOAPEventLogger.LogLevel.INFO)
## logger.flush()
## [/codeblock]
class_name GOAPEventLogger
extends RefCounted

## Log level enum.
enum LogLevel {
	DEBUG,   ## Detailed debug information
	INFO,    ## General information
	WARN,    ## Warning messages
	ERROR,   ## Error messages
}

## Current log file path.
var log_file_path: String = ""

## Maximum log file size in bytes before rotation.
var max_file_size: int = 10 * 1024 * 1024  # 10 MB

## Current log level filter.
var min_log_level: LogLevel = LogLevel.INFO

## Whether to output to console.
var console_output_enabled: bool = true

## Current log file handle.
var _log_file: FileAccess = null

## Log buffer for batch writes.
var _log_buffer: Array[String] = []

## Buffer flush interval in seconds.
var _flush_interval: float = 5.0

## Last flush time.
var _last_flush_time: float = 0.0


func _init() -> void:
	# Default log path
	set_log_file_path("user://goap_logs/goap_debug.log")


## Sets the log file path.[br][br]
##
## Creates directory if it doesn't exist.[br][br]
##
## [param path] Path to log file.
func set_log_file_path(path: String) -> void:
	# Close existing file
	if _log_file:
		flush()
		_log_file.close()
		_log_file = null

	log_file_path = path

	# Create directory
	var dir_path := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Check if rotation needed
	if FileAccess.file_exists(path):
		var size := FileAccess.get_modified_time(path)
		if size > max_file_size:
			_rotate_log_file()

	# Open file for append
	_log_file = FileAccess.open(path, FileAccess.WRITE_READ)
	if _log_file:
		_log_file.seek_end()
	else:
		push_error("[GOAPEventLogger] Failed to open log file: ", path)


## Sets maximum file size before rotation.[br][br]
##
## [param bytes] Size in bytes.
func set_max_file_size(bytes: int) -> void:
	max_file_size = bytes


## Logs a debug event.[br][br]
##
## [param event] Event to log.[br]
## [param level] Log level (default INFO).
func log_event(event: DebugEvent, level: LogLevel = LogLevel.INFO) -> void:
	if level < min_log_level:
		return

	var log_line := _format_event(event, level)

	# Add to buffer
	_log_buffer.append(log_line)

	# Console output
	if console_output_enabled:
		_print_to_console(log_line, level)

	# Auto-flush if interval passed
	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_flush_time >= _flush_interval:
		flush()


## Logs a custom message.[br][br]
##
## [param message] Message to log.[br]
## [param level] Log level (default INFO).
func log_message(message: String, level: LogLevel = LogLevel.INFO) -> void:
	if level < min_log_level:
		return

	var timestamp := Time.get_datetime_string_from_system()
	var level_str: String = LogLevel.keys()[level]
	var log_line := "[%s] [%s] %s" % [timestamp, level_str, message]

	_log_buffer.append(log_line)

	if console_output_enabled:
		_print_to_console(log_line, level)

	var current_time := Time.get_ticks_msec() / 1000.0
	if current_time - _last_flush_time >= _flush_interval:
		flush()


## Flushes log buffer to file.
func flush() -> void:
	if not _log_file or _log_buffer.is_empty():
		return

	for line in _log_buffer:
		_log_file.store_line(line)

	_log_file.flush()
	_log_buffer.clear()
	_last_flush_time = Time.get_ticks_msec() / 1000.0


## Formats event as log line.[br][br]
##
## [param event] Event to format.[br]
## [param level] Log level.[br]
## [br]
## Returns formatted string.
func _format_event(event: DebugEvent, level: LogLevel) -> String:
	var timestamp := Time.get_datetime_string_from_system()
	var level_str: String = LogLevel.keys()[level]
	var agent_name: String = event.agent.name as String if event.agent else "Unknown"
	var event_type: String = DebugEvent.EventType.keys()[event.event_type]

	var goal: GOAPGoal = event.data.get("goal")
	var action: GOAPAction = event.data.get("action")

	var goal_name = goal.goal_name as String if goal else "Unknown"
	var action_name = action.action_name as String if action else "Unknown"

	var details := ""
	match event.event_type:
		DebugEvent.EventType.GOAL_SELECTED:
			details = "Goal: %s, Priority: %.1f" % [goal_name, event.data.get("priority", 0.0)]

		DebugEvent.EventType.PLAN_CREATED:
			var plan_size: int = event.data.get("plan_size", 0)
			details = "Goal: %s, Actions: %d" % [goal_name, plan_size]

		DebugEvent.EventType.PLAN_FAILED:
			var reason: String = event.data.get("reason", "Unknown")
			details = "Goal: %s, Reason: %s" % [goal_name, reason]

		DebugEvent.EventType.ACTION_STARTED:
			details = "Action: %s" % [action_name]

		DebugEvent.EventType.ACTION_ENDED:
			var result: GOAPAction.ExecResult = event.data.get("result", GOAPAction.ExecResult.SUCCESS)
			details = "Action: %s, Result: %s" % [
				action_name,
				GOAPAction.ExecResult.keys()[result]
			]

		DebugEvent.EventType.STATE_CHANGED:
			details = "Key: %s, New: %s, Old: %s" % [
				event.data.get("key", ""),
				str(event.data.get("new_value", "")),
				str(event.data.get("old_value", ""))
			]

		DebugEvent.EventType.METRIC_RECORDED:
			details = "Planning Time: %.2fms" % event.data.get("planning_time_ms", 0.0)

	return "[%s] [%s] [%s] %s: %s" % [timestamp, level_str, agent_name, event_type, details]


## Prints to console with color coding.[br][br]
##
## [param message] Message to print.[br]
## [param level] Log level.
func _print_to_console(message: String, level: LogLevel) -> void:
	match level:
		LogLevel.DEBUG:
			print_rich("[color=gray]", message, "[/color]")
		LogLevel.INFO:
			print(message)
		LogLevel.WARN:
			print_rich("[color=yellow]", message, "[/color]")
		LogLevel.ERROR:
			print_rich("[color=red]", message, "[/color]")


## Rotates log file (creates numbered backup).
func _rotate_log_file() -> void:
	if not FileAccess.file_exists(log_file_path):
		return

	# Find next available backup number
	var base_path := log_file_path.get_basename()
	var extension := log_file_path.get_extension()
	var backup_num := 1

	while FileAccess.file_exists("%s.%d.%s" % [base_path, backup_num, extension]):
		backup_num += 1

	# Rename current log
	var backup_path := "%s.%d.%s" % [base_path, backup_num, extension]
	DirAccess.rename_absolute(log_file_path, backup_path)

	print("[GOAPEventLogger] Rotated log file to: ", backup_path)
