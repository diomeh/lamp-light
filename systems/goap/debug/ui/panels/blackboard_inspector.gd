## Blackboard inspector panel for GOAP debug overlay.
##
## Displays and monitors agent blackboard state with real-time updates.[br][br]
##
## [b]Features:[/b]
## - Real-time blackboard value display
## - Type information for each entry
## - Search/filter functionality
## - Change highlighting
## - Value history tracking[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## blackboard_inspector.refresh(agent)
## [/codeblock]
extends Control

## Tree for blackboard entries.
@onready var blackboard_tree: Tree = %BlackboardTree

## Search/filter input.
@onready var search_input: LineEdit = %SearchInput

## Clear search button.
@onready var clear_search_button: Button = %ClearSearchButton

## Refresh button.
@onready var refresh_button: Button = %RefreshButton

## Show types checkbox.
@onready var show_types_checkbox: CheckBox = %ShowTypesCheckBox

## Highlight changes checkbox.
@onready var highlight_changes_checkbox: CheckBox = %HighlightChangesCheckBox

## Entry count label.
@onready var entry_count_label: Label = %EntryCountLabel

## Currently displayed agent.
var _current_agent: GOAPAgent = null

## Previous blackboard state (for change detection).
var _previous_state: Dictionary = {}

## Changed keys in last refresh.
var _changed_keys: Array[String] = []

## Auto-refresh enabled.
var _auto_refresh: bool = true

## Refresh interval in seconds.
var _refresh_interval: float = 0.5

## Time since last refresh.
var _time_since_refresh: float = 0.0

## Search filter text.
var _search_filter: String = ""


func _ready() -> void:
	# Setup tree
	if blackboard_tree:
		blackboard_tree.set_column_titles_visible(true)
		blackboard_tree.set_columns(3)
		blackboard_tree.set_column_title(0, "Key")
		blackboard_tree.set_column_title(1, "Value")
		blackboard_tree.set_column_title(2, "Type")
		blackboard_tree.set_column_expand(0, true)
		blackboard_tree.set_column_expand(1, true)
		blackboard_tree.set_column_expand(2, false)
		blackboard_tree.set_column_custom_minimum_width(2, 100)

	# Connect signals
	if search_input:
		search_input.text_changed.connect(_on_search_text_changed)
	if clear_search_button:
		clear_search_button.pressed.connect(_on_clear_search_pressed)
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)

	_clear_display()


func _process(delta: float) -> void:
	if not _auto_refresh or not _current_agent:
		return

	_time_since_refresh += delta
	if _time_since_refresh >= _refresh_interval:
		refresh(_current_agent)
		_time_since_refresh = 0.0


## Refreshes panel with agent blackboard data.[br][br]
##
## [param agent] Agent to display.
func refresh(agent: GOAPAgent) -> void:
	if not agent or not is_instance_valid(agent):
		_clear_display()
		return

	_current_agent = agent

	# Get current blackboard state
	var current_state := agent.blackboard.to_dict()

	# Detect changes
	_detect_changes(current_state)

	# Update tree
	_update_tree(current_state)

	# Update previous state
	_previous_state = current_state.duplicate(true)

	# Update entry count
	if entry_count_label:
		var total_count := current_state.size()
		var visible_count := _count_visible_entries(current_state)
		if _search_filter.is_empty():
			entry_count_label.text = "%d entries" % total_count
		else:
			entry_count_label.text = "%d / %d entries" % [visible_count, total_count]


## Detects changed keys since last refresh.[br][br]
##
## [param current_state] Current blackboard state.
func _detect_changes(current_state: Dictionary) -> void:
	_changed_keys.clear()

	# Check for new or changed keys
	for key in current_state:
		if not _previous_state.has(key):
			_changed_keys.append(key)
		elif current_state[key] != _previous_state[key]:
			_changed_keys.append(key)

	# Check for removed keys
	for key in _previous_state:
		if not current_state.has(key):
			_changed_keys.append(key)


## Updates the blackboard tree display.[br][br]
##
## [param state] Blackboard state dictionary.
func _update_tree(state: Dictionary) -> void:
	if not blackboard_tree:
		return

	blackboard_tree.clear()
	var root := blackboard_tree.create_item()

	# Get sorted keys
	var keys := state.keys()
	keys.sort()

	# Add entries
	for key in keys:
		var value_str: String

		# Apply search filter
		if not _search_filter.is_empty():
			if not key.to_lower().contains(_search_filter.to_lower()):
				value_str = str(state[key]).to_lower()
				if not value_str.contains(_search_filter.to_lower()):
					continue

		var item := blackboard_tree.create_item(root)

		# Key column
		item.set_text(0, str(key))

		# Value column
		var value = state[key]
		value_str = _format_value(value)
		item.set_text(1, value_str)

		# Type column (if enabled)
		if show_types_checkbox and show_types_checkbox.button_pressed:
			var type_str := _get_type_name(value)
			item.set_text(2, type_str)

		# Highlight changes
		if highlight_changes_checkbox and highlight_changes_checkbox.button_pressed:
			if key in _changed_keys:
				item.set_custom_bg_color(0, Color(0.3, 0.5, 0.3, 0.3))
				item.set_custom_bg_color(1, Color(0.3, 0.5, 0.3, 0.3))
				item.set_custom_bg_color(2, Color(0.3, 0.5, 0.3, 0.3))


## Formats a value for display.[br][br]
##
## [param value] Value to format.[br]
## [br]
## Returns formatted string.
func _format_value(value: Variant) -> String:
	if value == null:
		return "null"
	elif value is bool:
		return "true" if value else "false"
	elif value is float:
		return "%.3f" % value
	elif value is Vector2:
		return "(%.1f, %.1f)" % [value.x, value.y]
	elif value is Vector3:
		return "(%.1f, %.1f, %.1f)" % [value.x, value.y, value.z]
	elif value is String:
		return "\"%s\"" % value
	elif value is Array:
		return "[Array: %d items]" % value.size()
	elif value is Dictionary:
		return "{Dictionary: %d entries}" % value.size()
	elif value is Object:
		if value.has_method("get_class"):
			return "<%s>" % value.get_class()
		return "<Object>"
	else:
		return str(value)


## Gets type name for a value.[br][br]
##
## [param value] Value to get type of.[br]
## [br]
## Returns type name string.
func _get_type_name(value: Variant) -> String:
	var type_id := typeof(value)
	match type_id:
		TYPE_NIL:
			return "Nil"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "String"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR3:
			return "Vector3"
		TYPE_VECTOR4:
			return "Vector4"
		TYPE_ARRAY:
			return "Array"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_OBJECT:
			if value and value.has_method("get_class"):
				return value.get_class()
			return "Object"
		_:
			return "Unknown"


## Counts visible entries after filter.[br][br]
##
## [param state] Blackboard state.[br]
## [br]
## Returns count of visible entries.
func _count_visible_entries(state: Dictionary) -> int:
	if _search_filter.is_empty():
		return state.size()

	var count := 0
	for key in state:
		if key.to_lower().contains(_search_filter.to_lower()):
			count += 1
			continue
		var value_str := str(state[key]).to_lower()
		if value_str.contains(_search_filter.to_lower()):
			count += 1

	return count


## Clears all display fields.
func _clear_display() -> void:
	_current_agent = null
	_previous_state.clear()
	_changed_keys.clear()

	if blackboard_tree:
		blackboard_tree.clear()
	if entry_count_label:
		entry_count_label.text = "0 entries"


## Sets auto-refresh enabled.[br][br]
##
## [param enabled] Enable/disable auto-refresh.
func set_auto_refresh(enabled: bool) -> void:
	_auto_refresh = enabled


## Signal handlers

func _on_search_text_changed(new_text: String) -> void:
	_search_filter = new_text
	if _current_agent:
		refresh(_current_agent)


func _on_clear_search_pressed() -> void:
	if search_input:
		search_input.text = ""
		_search_filter = ""
	if _current_agent:
		refresh(_current_agent)


func _on_refresh_pressed() -> void:
	if _current_agent:
		refresh(_current_agent)
