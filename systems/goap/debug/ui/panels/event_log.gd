## Event log panel for GOAP debug overlay.
##
## Displays filterable stream of debug events.[br][br]
##
## [b]Features:[/b]
## - Real-time event stream
## - Event type filtering
## - Search functionality
## - Event detail expansion
## - Export to file
## - Auto-scroll toggle[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## event_log.add_event(event)
## [/codeblock]
extends Control

## Rich text label for event log.
@onready var log_text: RichTextLabel = %LogText

## Search input.
@onready var search_input: LineEdit = %SearchInput

## Clear log button.
@onready var clear_button: Button = %ClearButton

## Export button.
@onready var export_button: Button = %ExportButton

## Auto-scroll checkbox.
@onready var auto_scroll_checkbox: CheckBox = %AutoScrollCheckBox

## Filter container for event types.
@onready var filter_container: HBoxContainer = %FilterContainer

## Event count label.
@onready var event_count_label: Label = %EventCountLabel

## Currently displayed agent.
var _current_agent: GOAPAgent = null

## Event filter flags (event type -> enabled).
var _event_filters: Dictionary = {}

## Search filter text.
var _search_filter: String = ""

## Maximum events to display.
const MAX_DISPLAY_EVENTS: int = 1000

## Auto-refresh enabled.
var _auto_refresh: bool = true

## Refresh interval in seconds.
var _refresh_interval: float = 0.5

## Time since last refresh.
var _time_since_refresh: float = 0.0


func _ready() -> void:
	# Initialize filters (all enabled by default)
	for event_type in DebugEvent.EventType.values():
		_event_filters[event_type] = true

	# Setup filter checkboxes
	_setup_filters()

	# Connect signals
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	if export_button:
		export_button.pressed.connect(_on_export_pressed)
	if search_input:
		search_input.text_changed.connect(_on_search_changed)

	# Connect to debug manager
	if GOAPDebugManager:
		GOAPDebugManager.debug_event_recorded.connect(_on_debug_event_recorded)

	_clear_display()


func _process(delta: float) -> void:
	if not _auto_refresh or not _current_agent:
		return

	_time_since_refresh += delta
	if _time_since_refresh >= _refresh_interval:
		refresh(_current_agent)
		_time_since_refresh = 0.0


## Sets up event type filter checkboxes.[br][br]
func _setup_filters() -> void:
	if not filter_container:
		return

	for event_type in DebugEvent.EventType.values():
		var checkbox := CheckBox.new()
		checkbox.text = DebugEvent.EventType.keys()[event_type]
		checkbox.button_pressed = true
		checkbox.toggled.connect(_on_filter_toggled.bind(event_type))
		filter_container.add_child(checkbox)


## Refreshes panel with agent events.[br][br]
##
## [param agent] Agent to display.
func refresh(agent: GOAPAgent) -> void:
	if not agent or not is_instance_valid(agent):
		_clear_display()
		return

	_current_agent = agent

	# Get and display events
	_display_events()


## Displays events in the log.[br][br]
func _display_events() -> void:
	if not log_text or not GOAPDebugManager:
		return

	# Get events for current agent
	var events := GOAPDebugManager.get_events_for_agent(_current_agent, MAX_DISPLAY_EVENTS)

	# Filter events
	var filtered_events: Array[DebugEvent] = []
	for event in events:
		if not _should_display_event(event):
			continue
		filtered_events.append(event)

	# Update count
	if event_count_label:
		event_count_label.text = "%d / %d events" % [filtered_events.size(), events.size()]

	# Build log text
	log_text.clear()
	log_text.push_table(1)

	for event in filtered_events:
		_add_event_to_log(event)

	log_text.pop()  # table

	# Auto-scroll to bottom
	if auto_scroll_checkbox and auto_scroll_checkbox.button_pressed:
		log_text.scroll_to_line(log_text.get_line_count() - 1)


## Adds a single event to the log display.[br][br]
##
## [param event] Event to add.
func add_event(event: DebugEvent) -> void:
	if not _current_agent or event.agent != _current_agent:
		return

	if not _should_display_event(event):
		return

	if not log_text:
		return

	# Add to existing log
	_add_event_to_log(event)

	# Update count
	if event_count_label and GOAPDebugManager:
		var total_events := GOAPDebugManager.get_events_for_agent(_current_agent, MAX_DISPLAY_EVENTS).size()
		var display_count := log_text.get_line_count()
		event_count_label.text = "%d / %d events" % [display_count, total_events]

	# Auto-scroll
	if auto_scroll_checkbox and auto_scroll_checkbox.button_pressed:
		log_text.scroll_to_line(log_text.get_line_count() - 1)


## Adds event to log with formatting.[br][br]
##
## [param event] Event to add.
func _add_event_to_log(event: DebugEvent) -> void:
	if not log_text:
		return

	log_text.push_cell()

	# Timestamp
	log_text.push_color(Color(0.6, 0.6, 0.6))
	log_text.add_text("[%.2fs] " % event.timestamp)
	log_text.pop()  # color

	# Event type with color
	var event_type_name: String = DebugEvent.EventType.keys()[event.event_type]
	var type_color := _get_event_type_color(event.event_type)
	log_text.push_color(type_color)
	log_text.add_text("[%s] " % event_type_name)
	log_text.pop()  # color

	# Event details
	var details := _format_event_details(event)
	log_text.add_text(details)

	log_text.add_text("\n")

	log_text.pop()  # cell


## Checks if event should be displayed based on filters.[br][br]
##
## [param event] Event to check.[br]
## [br]
## Returns [code]true[/code] if should display.
func _should_display_event(event: DebugEvent) -> bool:
	# Check event type filter
	if not _event_filters.get(event.event_type, true):
		return false

	# Check search filter
	if not _search_filter.is_empty():
		var event_text: String = DebugEvent.EventType.keys()[event.event_type].to_lower()
		var details := _format_event_details(event).to_lower()

		if not event_text.contains(_search_filter.to_lower()) and not details.contains(_search_filter.to_lower()):
			return false

	return true


## Formats event details for display.[br][br]
##
## [param event] Event to format.[br]
## [br]
## Returns formatted string.
func _format_event_details(event: DebugEvent) -> String:
	var goal: GOAPGoal = event.data.get("goal")
	var action: GOAPAction = event.data.get("action")

	var goal_name = goal.goal_name as String if goal else "Unknown"
	var action_name = action.action_name as String if action else "Unknown"

	match event.event_type:

		DebugEvent.EventType.GOAL_SELECTED:
			var priority: float = event.data.get("priority", 0.0)
			return "Goal: %s (priority: %.1f)" % [goal_name, priority]

		DebugEvent.EventType.PLAN_CREATED:
			var plan_size: int = event.data.get("plan_size", 0)
			return "Goal: %s, %d actions" % [goal_name, plan_size]

		DebugEvent.EventType.PLAN_FAILED:
			var reason: String = event.data.get("reason", "")
			if reason.is_empty():
				return "Goal: %s" % [goal_name]
			return "Goal: %s, Reason: %s" % [goal_name, reason]

		DebugEvent.EventType.PLAN_COMPLETED:
			return "Goal: %s" % [goal_name]

		DebugEvent.EventType.PLAN_ABORTED:
			return "Goal: %s, Action: %s" % [goal_name, action_name]

		DebugEvent.EventType.ACTION_STARTED:
			return "Action: %s" % [action_name]

		DebugEvent.EventType.ACTION_ENDED:
			var result: GOAPAction.ExecResult = event.data.get("result", GOAPAction.ExecResult.SUCCESS)
			return "Action: %s, Result: %s" % [action_name, GOAPAction.ExecResult.keys()[result]]

		DebugEvent.EventType.STATE_CHANGED:
			var key: String = event.data.get("key", "")
			var new_value = event.data.get("new_value")
			var old_value = event.data.get("old_value")
			return "Key: %s, %s -> %s" % [key, str(old_value), str(new_value)]

		DebugEvent.EventType.METRIC_RECORDED:
			var planning_time: float = event.data.get("planning_time_ms", 0.0)
			return "Planning time: %.2fms" % planning_time

	return ""


## Gets color for event type.[br][br]
##
## [param event_type] Event type.[br]
## [br]
## Returns color.
func _get_event_type_color(event_type: DebugEvent.EventType) -> Color:
	match event_type:
		DebugEvent.EventType.GOAL_SELECTED:
			return Color(0.3, 0.8, 1.0)
		DebugEvent.EventType.PLAN_CREATED:
			return Color(0.3, 1.0, 0.3)
		DebugEvent.EventType.PLAN_FAILED, DebugEvent.EventType.PLAN_ABORTED:
			return Color(1.0, 0.3, 0.3)
		DebugEvent.EventType.PLAN_COMPLETED:
			return Color(0.3, 1.0, 0.5)
		DebugEvent.EventType.ACTION_STARTED:
			return Color(1.0, 1.0, 0.5)
		DebugEvent.EventType.ACTION_ENDED:
			return Color(0.8, 0.8, 0.3)
		DebugEvent.EventType.STATE_CHANGED:
			return Color(0.7, 0.7, 1.0)
		DebugEvent.EventType.METRIC_RECORDED:
			return Color(0.5, 0.5, 0.5)
	return Color.WHITE


## Clears all display fields.
func _clear_display() -> void:
	_current_agent = null

	if log_text:
		log_text.clear()
	if event_count_label:
		event_count_label.text = "0 / 0 events"


## Sets auto-refresh enabled.[br][br]
##
## [param enabled] Enable/disable auto-refresh.
func set_auto_refresh(enabled: bool) -> void:
	_auto_refresh = enabled


## Signal handlers

func _on_clear_pressed() -> void:
	if log_text:
		log_text.clear()
	if event_count_label:
		event_count_label.text = "0 / 0 events"


func _on_export_pressed() -> void:
	if not GOAPDebugManager:
		return

	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var filename := "user://goap_events_%s.json" % timestamp
	var err := GOAPDebugManager.export_events_to_json(filename)

	if err == OK:
		print("[EventLog] Exported events to: ", filename)
	else:
		push_error("[EventLog] Failed to export events: ", err)


func _on_search_changed(new_text: String) -> void:
	_search_filter = new_text
	if _current_agent:
		refresh(_current_agent)


func _on_filter_toggled(toggled_on: bool, event_type: int) -> void:
	_event_filters[event_type] = toggled_on
	if _current_agent:
		refresh(_current_agent)


func _on_debug_event_recorded(event: DebugEvent) -> void:
	# Real-time event addition
	add_event(event)
