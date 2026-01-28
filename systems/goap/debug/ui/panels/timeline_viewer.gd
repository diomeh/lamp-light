## Timeline viewer panel for GOAP debug overlay.
##
## Displays execution timeline with goals, plans, and actions.[br][br]
##
## [b]Features:[/b]
## - Gantt-style timeline visualization
## - Goal/plan/action duration display
## - Time range controls (zoom, pan)
## - Success/failure status coloring
## - Time markers and grid[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## timeline_viewer.refresh(agent)
## [/codeblock]
extends Control

## Timeline canvas for drawing.
@onready var timeline_canvas: Control = %TimelineCanvas

## Time range start input.
@onready var time_start_input: SpinBox = %TimeStartInput

## Time range end input.
@onready var time_end_input: SpinBox = %TimeEndInput

## Zoom slider.
@onready var zoom_slider: HSlider = %ZoomSlider

## Auto-range button.
@onready var auto_range_button: Button = %AutoRangeButton

## Refresh button.
@onready var refresh_button: Button = %RefreshButton

## Clear button.
@onready var clear_button: Button = %ClearButton

## Currently displayed agent.
var _current_agent: GOAPAgent = null

## Timeline entries for current agent.
var _timeline_entries: Array[TimelineEntry] = []

## Time range (start, end in seconds).
var _time_range: Vector2 = Vector2(0.0, 60.0)

## Zoom level (pixels per second).
var _zoom: float = 10.0

## Auto-refresh enabled.
var _auto_refresh: bool = true

## Refresh interval in seconds.
var _refresh_interval: float = 1.0

## Time since last refresh.
var _time_since_refresh: float = 0.0

## Row height in pixels.
const ROW_HEIGHT: int = 40

## Row spacing in pixels.
const ROW_SPACING: int = 8

## Left margin for labels.
const LEFT_MARGIN: int = 120


func _ready() -> void:
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	if auto_range_button:
		auto_range_button.pressed.connect(_on_auto_range_pressed)
	if zoom_slider:
		zoom_slider.value_changed.connect(_on_zoom_changed)
	if time_start_input:
		time_start_input.value_changed.connect(_on_time_range_changed)
	if time_end_input:
		time_end_input.value_changed.connect(_on_time_range_changed)

	if timeline_canvas:
		timeline_canvas.draw.connect(_on_timeline_draw)

	_clear_display()


func _process(delta: float) -> void:
	if not _auto_refresh or not _current_agent:
		return

	_time_since_refresh += delta
	if _time_since_refresh >= _refresh_interval:
		refresh(_current_agent)
		_time_since_refresh = 0.0


## Refreshes panel with agent timeline data.[br][br]
##
## [param agent] Agent to display.
func refresh(agent: GOAPAgent) -> void:
	if not agent or not is_instance_valid(agent):
		_clear_display()
		return

	_current_agent = agent

	# Update timeline entries from debug events
	_update_timeline_entries()

	# Auto-adjust range if needed
	if _timeline_entries.size() > 0:
		_auto_adjust_range()

	# Redraw canvas
	if timeline_canvas:
		timeline_canvas.queue_redraw()


## Updates timeline entries from debug events.[br][br]
func _update_timeline_entries() -> void:
	if not GOAPDebugManager:
		return

	# Get events for current agent
	var events := GOAPDebugManager.get_events_for_agent(_current_agent, 0)

	# Clear existing entries
	_timeline_entries.clear()

	# Track open entries (action/goal/plan starts without ends)
	var open_actions: Dictionary = {}  # action -> TimelineEntry
	var current_goal_entry: TimelineEntry = null

	# Process events chronologically
	for event in events:
		match event.event_type:
			DebugEvent.EventType.GOAL_SELECTED:
				# End previous goal if any
				if current_goal_entry:
					current_goal_entry.end_time = event.timestamp
					current_goal_entry.status = "completed"

				# Start new goal
				var goal: GOAPGoal = event.data.get("goal")
				if goal:
					current_goal_entry = TimelineEntry.new()
					current_goal_entry.start_time = event.timestamp
					current_goal_entry.entry_type = "goal"
					current_goal_entry.name = goal.goal_name
					current_goal_entry.status = "running"
					_timeline_entries.append(current_goal_entry)

			DebugEvent.EventType.ACTION_STARTED:
				var action: GOAPAction = event.data.get("action")
				if action:
					var entry := TimelineEntry.new()
					entry.start_time = event.timestamp
					entry.entry_type = "action"
					entry.name = action.action_name
					entry.status = "running"
					open_actions[action] = entry
					_timeline_entries.append(entry)

			DebugEvent.EventType.ACTION_ENDED:
				var action: GOAPAction = event.data.get("action")
				var result: GOAPAction.ExecResult = event.data.get("result", GOAPAction.ExecResult.SUCCESS)

				if action and open_actions.has(action):
					var entry: TimelineEntry = open_actions[action]
					entry.end_time = event.timestamp
					entry.status = "success" if result == GOAPAction.ExecResult.SUCCESS else "failure"
					open_actions.erase(action)

			DebugEvent.EventType.PLAN_COMPLETED:
				if current_goal_entry:
					current_goal_entry.end_time = event.timestamp
					current_goal_entry.status = "success"
					current_goal_entry = null

			DebugEvent.EventType.PLAN_FAILED, DebugEvent.EventType.PLAN_ABORTED:
				if current_goal_entry:
					current_goal_entry.end_time = event.timestamp
					current_goal_entry.status = "failure"
					current_goal_entry = null

	# Close any still-running entries
	if current_goal_entry and current_goal_entry.is_running():
		current_goal_entry.end_time = 0.0  # Still running
	for action in open_actions:
		var entry: TimelineEntry = open_actions[action]
		entry.end_time = 0.0  # Still running


## Auto-adjusts time range to fit all entries.[br][br]
func _auto_adjust_range() -> void:
	if _timeline_entries.is_empty():
		return

	var min_time := INF
	var max_time := -INF

	for entry in _timeline_entries:
		min_time = min(min_time, entry.start_time)
		if entry.end_time > 0.0:
			max_time = max(max_time, entry.end_time)
		else:
			max_time = max(max_time, Time.get_ticks_msec() / 1000.0)

	# Add padding
	var padding := (max_time - min_time) * 0.1
	_time_range.x = max(0.0, min_time - padding)
	_time_range.y = max_time + padding

	# Update inputs
	if time_start_input:
		time_start_input.value = _time_range.x
	if time_end_input:
		time_end_input.value = _time_range.y


## Draws the timeline.[br][br]
func _on_timeline_draw() -> void:
	if not timeline_canvas:
		return

	var canvas := timeline_canvas

	# Clear
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color(0.1, 0.1, 0.1, 1.0))

	if _timeline_entries.is_empty():
		var text := "No timeline data"
		canvas.draw_string(ThemeDB.fallback_font, Vector2(canvas.size.x / 2.0 - 50, canvas.size.y / 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.5, 0.5, 0.5))
		return

	# Draw time grid
	_draw_time_grid(canvas)

	# Group entries by type for lanes
	var goal_entries: Array[TimelineEntry] = []
	var action_entries: Array[TimelineEntry] = []

	for entry in _timeline_entries:
		if entry.entry_type == "goal":
			goal_entries.append(entry)
		elif entry.entry_type == "action":
			action_entries.append(entry)

	# Draw goal lane
	var y_pos := 20
	if not goal_entries.is_empty():
		canvas.draw_string(ThemeDB.fallback_font, Vector2(8, y_pos + 20), "Goals", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		for entry in goal_entries:
			_draw_timeline_entry(canvas, entry, y_pos)
			y_pos += ROW_HEIGHT + ROW_SPACING

	# Draw action lane
	if not action_entries.is_empty():
		y_pos += 20
		canvas.draw_string(ThemeDB.fallback_font, Vector2(8, y_pos + 20), "Actions", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		for entry in action_entries:
			_draw_timeline_entry(canvas, entry, y_pos)
			y_pos += ROW_HEIGHT + ROW_SPACING


## Draws time grid lines.[br][br]
##
## [param canvas] Canvas to draw on.
func _draw_time_grid(canvas: Control) -> void:
	var duration := _time_range.y - _time_range.x
	if duration <= 0:
		return

	# Calculate grid interval (1s, 5s, 10s, etc.)
	var interval := 1.0
	if duration > 60:
		interval = 10.0
	elif duration > 30:
		interval = 5.0

	var start_time: float = floor(_time_range.x / interval) * interval

	for t in range(int(start_time), int(_time_range.y) + 1, int(interval)):
		var x := _time_to_x(float(t))
		if x >= LEFT_MARGIN and x <= canvas.size.x:
			# Grid line
			canvas.draw_line(Vector2(x, 0), Vector2(x, canvas.size.y), Color(0.3, 0.3, 0.3, 0.5), 1.0)
			# Time label
			canvas.draw_string(ThemeDB.fallback_font, Vector2(x + 2, 12), "%.1fs" % t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6))


## Draws a timeline entry.[br][br]
##
## [param canvas] Canvas to draw on.[br]
## [param entry] Timeline entry to draw.[br]
## [param y_pos] Y position for entry.
func _draw_timeline_entry(canvas: Control, entry: TimelineEntry, y_pos: int) -> void:
	var start_x := _time_to_x(entry.start_time)

	var end_time := entry.end_time if entry.end_time > 0.0 else (Time.get_ticks_msec() / 1000.0)
	var end_x := _time_to_x(end_time)

	# Clamp to visible area
	start_x = max(start_x, LEFT_MARGIN)
	end_x = min(end_x, canvas.size.x)

	if end_x <= start_x:
		return

	# Get color based on status
	var color := _get_status_color(entry.status)

	# Draw bar
	var rect := Rect2(start_x, y_pos, end_x - start_x, ROW_HEIGHT)
	canvas.draw_rect(rect, color)

	# Draw border
	canvas.draw_rect(rect, Color.WHITE, false, 1.0)

	# Draw label
	var label := "%s (%.2fs)" % [entry.name, entry.get_duration()]
	canvas.draw_string(
		ThemeDB.fallback_font,
		Vector2(start_x + 4, y_pos + (ROW_HEIGHT as float) / 2 + 6),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		rect.size.x - 8, 12,
		Color.WHITE
	)


## Converts time to X coordinate.[br][br]
##
## [param time] Time in seconds.[br]
## [br]
## Returns X coordinate.
func _time_to_x(time: float) -> float:
	var duration := _time_range.y - _time_range.x
	if duration <= 0:
		return LEFT_MARGIN

	var normalized := (time - _time_range.x) / duration
	var canvas_width: float = timeline_canvas.size.x - LEFT_MARGIN if timeline_canvas else 800.0
	return LEFT_MARGIN + normalized * canvas_width


## Gets color for status.[br][br]
##
## [param status] Entry status.[br]
## [br]
## Returns color.
func _get_status_color(status: String) -> Color:
	match status:
		"success":
			return Color(0.2, 0.6, 0.2, 0.8)
		"failure":
			return Color(0.8, 0.2, 0.2, 0.8)
		"running":
			return Color(0.6, 0.6, 0.2, 0.8)
		_:
			return Color(0.4, 0.4, 0.4, 0.8)


## Clears all display fields.
func _clear_display() -> void:
	_current_agent = null
	_timeline_entries.clear()

	if timeline_canvas:
		timeline_canvas.queue_redraw()


## Sets auto-refresh enabled.[br][br]
##
## [param enabled] Enable/disable auto-refresh.
func set_auto_refresh(enabled: bool) -> void:
	_auto_refresh = enabled


## Signal handlers

func _on_refresh_pressed() -> void:
	if _current_agent:
		refresh(_current_agent)


func _on_clear_pressed() -> void:
	_timeline_entries.clear()
	if timeline_canvas:
		timeline_canvas.queue_redraw()


func _on_auto_range_pressed() -> void:
	_auto_adjust_range()
	if timeline_canvas:
		timeline_canvas.queue_redraw()


func _on_zoom_changed(value: float) -> void:
	_zoom = value
	if timeline_canvas:
		timeline_canvas.queue_redraw()


func _on_time_range_changed(_value: float) -> void:
	if time_start_input and time_end_input:
		_time_range.x = time_start_input.value
		_time_range.y = time_end_input.value
		if timeline_canvas:
			timeline_canvas.queue_redraw()
