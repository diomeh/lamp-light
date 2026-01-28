## Performance monitor panel for GOAP debug overlay.
##
## Tracks and displays GOAP performance metrics.[br][br]
##
## [b]Metrics:[/b]
## - Planning time (average, min, max)
## - Plan success/failure rate
## - Action execution time
## - Plans per second
## - Memory usage (event buffer)[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## performance_monitor.refresh(agent)
## [/codeblock]
extends Control

## Planning time average label.
@onready var planning_avg_label: Label = %PlanningAvgLabel

## Planning time min label.
@onready var planning_min_label: Label = %PlanningMinLabel

## Planning time max label.
@onready var planning_max_label: Label = %PlanningMaxLabel

## Plans created count label.
@onready var plans_created_label: Label = %PlansCreatedLabel

## Plans failed count label.
@onready var plans_failed_label: Label = %PlansFailedLabel

## Plans completed count label.
@onready var plans_completed_label: Label = %PlansCompletedLabel

## Success rate label.
@onready var success_rate_label: Label = %SuccessRateLabel

## Actions executed count label.
@onready var actions_executed_label: Label = %ActionsExecutedLabel

## Actions failed count label.
@onready var actions_failed_label: Label = %ActionsFailedLabel

## Event buffer count label.
@onready var event_count_label: Label = %EventCountLabel

## Event buffer capacity label.
@onready var event_capacity_label: Label = %EventCapacityLabel

## Refresh button.
@onready var refresh_button: Button = %RefreshButton

## Reset stats button.
@onready var reset_button: Button = %ResetButton

## Currently displayed agent.
var _current_agent: GOAPAgent = null

## Collected performance metrics.
var _metrics: Dictionary = {
	"planning_times": [],
	"plans_created": 0,
	"plans_failed": 0,
	"plans_completed": 0,
	"plans_aborted": 0,
	"actions_executed": 0,
	"actions_failed": 0,
}

## Auto-refresh enabled.
var _auto_refresh: bool = true

## Refresh interval in seconds.
var _refresh_interval: float = 1.0

## Time since last refresh.
var _time_since_refresh: float = 0.0


func _ready() -> void:
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)

	_clear_display()


func _process(delta: float) -> void:
	if not _auto_refresh or not _current_agent:
		return

	_time_since_refresh += delta
	if _time_since_refresh >= _refresh_interval:
		refresh(_current_agent)
		_time_since_refresh = 0.0


## Refreshes panel with agent performance data.[br][br]
##
## [param agent] Agent to display.
func refresh(agent: GOAPAgent) -> void:
	if not agent or not is_instance_valid(agent):
		_clear_display()
		return

	_current_agent = agent

	# Collect metrics from debug events
	_collect_metrics()

	# Update display
	_update_display()


## Collects metrics from debug events.[br][br]
func _collect_metrics() -> void:
	if not GOAPDebugManager:
		return

	# Reset metrics
	_metrics = {
		"planning_times": [],
		"plans_created": 0,
		"plans_failed": 0,
		"plans_completed": 0,
		"plans_aborted": 0,
		"actions_executed": 0,
		"actions_failed": 0,
	}

	# Get events for current agent
	var events := GOAPDebugManager.get_events_for_agent(_current_agent, 0)

	# Process events
	for event in events:
		match event.event_type:
			DebugEvent.EventType.PLAN_CREATED:
				_metrics["plans_created"] += 1

			DebugEvent.EventType.PLAN_FAILED:
				_metrics["plans_failed"] += 1

			DebugEvent.EventType.PLAN_COMPLETED:
				_metrics["plans_completed"] += 1

			DebugEvent.EventType.PLAN_ABORTED:
				_metrics["plans_aborted"] += 1

			DebugEvent.EventType.ACTION_ENDED:
				_metrics["actions_executed"] += 1
				var result: GOAPAction.ExecResult = event.data.get("result", GOAPAction.ExecResult.SUCCESS)
				if result != GOAPAction.ExecResult.SUCCESS:
					_metrics["actions_failed"] += 1

			DebugEvent.EventType.METRIC_RECORDED:
				var planning_time: float = event.data.get("planning_time_ms", 0.0)
				if planning_time > 0.0:
					_metrics["planning_times"].append(planning_time)


## Updates the display with collected metrics.[br][br]
func _update_display() -> void:
	# Planning times
	var planning_times: Array = _metrics["planning_times"]
	if not planning_times.is_empty():
		var avg := 0.0
		var min_time := INF
		var max_time := -INF

		for time in planning_times:
			avg += time
			min_time = min(min_time, time)
			max_time = max(max_time, time)

		avg /= planning_times.size()

		if planning_avg_label:
			planning_avg_label.text = "%.2f ms" % avg
		if planning_min_label:
			planning_min_label.text = "%.2f ms" % min_time
		if planning_max_label:
			planning_max_label.text = "%.2f ms" % max_time
	else:
		if planning_avg_label:
			planning_avg_label.text = "-"
		if planning_min_label:
			planning_min_label.text = "-"
		if planning_max_label:
			planning_max_label.text = "-"

	# Plan counts
	if plans_created_label:
		plans_created_label.text = str(_metrics["plans_created"])
	if plans_failed_label:
		plans_failed_label.text = str(_metrics["plans_failed"])
	if plans_completed_label:
		plans_completed_label.text = str(_metrics["plans_completed"])

	# Success rate
	if success_rate_label:
		var total_plans: int = _metrics["plans_created"]
		if total_plans > 0:
			var success_rate: float = float(_metrics["plans_completed"]) / float(total_plans) * 100.0
			success_rate_label.text = "%.1f%%" % success_rate
		else:
			success_rate_label.text = "-"

	# Action counts
	if actions_executed_label:
		actions_executed_label.text = str(_metrics["actions_executed"])
	if actions_failed_label:
		actions_failed_label.text = str(_metrics["actions_failed"])

	# Event buffer stats
	if event_count_label and GOAPDebugManager:
		var all_events := GOAPDebugManager.get_all_events(0)
		event_count_label.text = str(all_events.size())
	if event_capacity_label and GOAPDebugManager:
		event_capacity_label.text = str(GOAPDebugManager.max_events)


## Clears all display fields.
func _clear_display() -> void:
	_current_agent = null

	if planning_avg_label:
		planning_avg_label.text = "-"
	if planning_min_label:
		planning_min_label.text = "-"
	if planning_max_label:
		planning_max_label.text = "-"
	if plans_created_label:
		plans_created_label.text = "0"
	if plans_failed_label:
		plans_failed_label.text = "0"
	if plans_completed_label:
		plans_completed_label.text = "0"
	if success_rate_label:
		success_rate_label.text = "-"
	if actions_executed_label:
		actions_executed_label.text = "0"
	if actions_failed_label:
		actions_failed_label.text = "0"
	if event_count_label:
		event_count_label.text = "0"
	if event_capacity_label:
		event_capacity_label.text = "-"


## Sets auto-refresh enabled.[br][br]
##
## [param enabled] Enable/disable auto-refresh.
func set_auto_refresh(enabled: bool) -> void:
	_auto_refresh = enabled


## Signal handlers

func _on_refresh_pressed() -> void:
	if _current_agent:
		refresh(_current_agent)


func _on_reset_pressed() -> void:
	if GOAPDebugManager:
		GOAPDebugManager.clear_events()
	_metrics = {
		"planning_times": [],
		"plans_created": 0,
		"plans_failed": 0,
		"plans_completed": 0,
		"plans_aborted": 0,
		"actions_executed": 0,
		"actions_failed": 0,
	}
	_update_display()
