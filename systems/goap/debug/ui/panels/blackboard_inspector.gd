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

## Show inherited values checkbox.
@onready var show_inherited_checkbox: CheckBox = %ShowInheritedCheckBox

## Show parent chain checkbox.
@onready var show_parent_chain_checkbox: CheckBox = %ShowParentChainCheckBox

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
		blackboard_tree.set_columns(4)
		blackboard_tree.set_column_title(0, "Key")
		blackboard_tree.set_column_title(1, "Value")
		blackboard_tree.set_column_title(2, "Type")
		blackboard_tree.set_column_title(3, "Source")
		blackboard_tree.set_column_expand(0, true)
		blackboard_tree.set_column_expand(1, true)
		blackboard_tree.set_column_expand(2, false)
		blackboard_tree.set_column_expand(3, false)
		blackboard_tree.set_column_custom_minimum_width(2, 100)
		blackboard_tree.set_column_custom_minimum_width(3, 120)

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

	# Get current blackboard state (local only or flattened based on show_inherited)
	var current_state: Dictionary
	var show_inherited := show_inherited_checkbox and show_inherited_checkbox.button_pressed

	if show_inherited and agent.blackboard.has_parent():
		current_state = agent.blackboard.flatten()
	else:
		current_state = agent.blackboard.to_dict()

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

	# Check if we're showing hierarchy
	var has_hierarchy := _current_agent and _current_agent.blackboard.has_parent()
	var show_inherited := show_inherited_checkbox and show_inherited_checkbox.button_pressed
	var show_parent_chain := show_parent_chain_checkbox and show_parent_chain_checkbox.button_pressed

	# Add parent chain visualization if enabled
	if show_parent_chain and has_hierarchy:
		_add_parent_chain_visualization(root)

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

		# Determine source of value
		var is_local := _current_agent.blackboard.has_value(key, true)
		var source_text := ""
		var is_override := false

		if has_hierarchy and show_inherited:
			if is_local:
				# Check if it overrides parent
				var parent_has := false
				if _current_agent.blackboard.has_parent():
					parent_has = _current_agent.blackboard.get_parent().has_value(key, false)
				source_text = "[Local]"
				is_override = parent_has
			else:
				source_text = "[Inherited]"
		else:
			source_text = "[Local]"

		# Key column (prefix with marker if inherited)
		var key_text := str(key)
		if has_hierarchy and show_inherited and not is_local:
			key_text = "\u2191 " + key_text  # Up arrow for inherited
			item.set_custom_color(0, Color(0.7, 0.7, 0.8))
		item.set_text(0, key_text)

		# Value column
		var value = state[key]
		value_str = _format_value(value)
		item.set_text(1, value_str)
		if has_hierarchy and show_inherited and not is_local:
			item.set_custom_color(1, Color(0.7, 0.7, 0.8))

		# Type column (if enabled)
		if show_types_checkbox and show_types_checkbox.button_pressed:
			var type_str := _get_type_name(value)
			item.set_text(2, type_str)
			if has_hierarchy and show_inherited and not is_local:
				item.set_custom_color(2, Color(0.7, 0.7, 0.8))

		# Source column
		if is_override:
			source_text += " [OVERRIDE]"
			item.set_custom_color(3, Color(1.0, 0.8, 0.3))
		item.set_text(3, source_text)

		# Highlight changes
		if highlight_changes_checkbox and highlight_changes_checkbox.button_pressed:
			if key in _changed_keys:
				item.set_custom_bg_color(0, Color(0.3, 0.5, 0.3, 0.3))
				item.set_custom_bg_color(1, Color(0.3, 0.5, 0.3, 0.3))
				item.set_custom_bg_color(2, Color(0.3, 0.5, 0.3, 0.3))
				item.set_custom_bg_color(3, Color(0.3, 0.5, 0.3, 0.3))


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


## Adds parent chain visualization to tree.[br][br]
##
## [param root] Root tree item.
func _add_parent_chain_visualization(root: TreeItem) -> void:
	if not _current_agent or not _current_agent.blackboard.has_parent():
		return

	var chain_item := blackboard_tree.create_item(root)
	chain_item.set_text(0, "--- Parent Chain ---")
	chain_item.set_selectable(0, false)
	chain_item.set_custom_color(0, Color(0.5, 0.5, 0.6))

	var current := _current_agent.blackboard.get_parent()
	var level := 1
	while current != null:
		var parent_item := blackboard_tree.create_item(chain_item)
		var value_count := current.to_dict().size()
		parent_item.set_text(0, "Parent Level %d" % level)
		parent_item.set_text(1, "%d values" % value_count)
		parent_item.set_custom_color(0, Color(0.6, 0.6, 0.7))
		parent_item.set_custom_color(1, Color(0.6, 0.6, 0.7))
		parent_item.set_selectable(0, false)
		level += 1
		current = current.get_parent()

	# Add separator
	var separator := blackboard_tree.create_item(root)
	separator.set_text(0, "--- Current State ---")
	separator.set_selectable(0, false)
	separator.set_custom_color(0, Color(0.5, 0.5, 0.6))


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
