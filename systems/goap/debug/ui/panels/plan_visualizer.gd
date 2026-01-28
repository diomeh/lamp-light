## Plan visualizer panel for GOAP debug overlay.
##
## Displays the current plan as a visual graph of actions.[br][br]
##
## [b]Features:[/b]
## - Visual action sequence display
## - Current action highlighting
## - Preconditions and effects display
## - Action cost and status
## - Zoom and pan controls[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## plan_visualizer.refresh(agent)
## [/codeblock]
extends Control

## Container for plan info header.
@onready var info_container: HBoxContainer = %InfoContainer

## Goal name label.
@onready var goal_label: Label = %GoalLabel

## Plan size label.
@onready var plan_size_label: Label = %PlanSizeLabel

## Total cost label.
@onready var total_cost_label: Label = %TotalCostLabel

## Progress label.
@onready var progress_label: Label = %ProgressLabel

## Scroll container for action list.
@onready var scroll_container: ScrollContainer = %ScrollContainer

## Container for action nodes.
@onready var actions_container: VBoxContainer = %ActionsContainer

## Refresh button.
@onready var refresh_button: Button = %RefreshButton

## Show details checkbox.
@onready var show_details_checkbox: CheckBox = %ShowDetailsCheckBox

## Currently displayed agent.
var _current_agent: GOAPAgent = null

## Auto-refresh enabled.
var _auto_refresh: bool = true

## Refresh interval in seconds.
var _refresh_interval: float = 0.5

## Time since last refresh.
var _time_since_refresh: float = 0.0


func _ready() -> void:
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
	if show_details_checkbox:
		show_details_checkbox.toggled.connect(_on_show_details_toggled)

	_clear_display()


func _process(delta: float) -> void:
	if not _auto_refresh or not _current_agent:
		return

	_time_since_refresh += delta
	if _time_since_refresh >= _refresh_interval:
		refresh(_current_agent)
		_time_since_refresh = 0.0


## Refreshes panel with agent plan data.[br][br]
##
## [param agent] Agent to display.
func refresh(agent: GOAPAgent) -> void:
	if not agent or not is_instance_valid(agent):
		_clear_display()
		return

	_current_agent = agent

	# Update header info
	_update_header_info(agent)

	# Update action list
	_update_action_list(agent)


## Updates header information.[br][br]
##
## [param agent] Agent to get info from.
func _update_header_info(agent: GOAPAgent) -> void:
	# Goal
	if goal_label:
		if agent.current_goal:
			goal_label.text = agent.current_goal.goal_name
		else:
			goal_label.text = "[color=gray]None[/color]"

	# Get plan from executor
	var plan: Array[GOAPAction] = []
	var current_index := 0
	var total_cost := 0.0

	if agent._executor and agent._executor.is_running():
		plan = agent._executor._plan if agent._executor._plan else []
		current_index = agent._executor.get_current_index()

		# Calculate total cost
		for action in plan:
			total_cost += action.cost

	# Plan size
	if plan_size_label:
		plan_size_label.text = "%d actions" % plan.size()

	# Total cost
	if total_cost_label:
		total_cost_label.text = "%.1f" % total_cost

	# Progress
	if progress_label:
		if plan.size() > 0:
			progress_label.text = "%d / %d" % [current_index + 1, plan.size()]
		else:
			progress_label.text = "0 / 0"


## Updates the action list display.[br][br]
##
## [param agent] Agent to get plan from.
func _update_action_list(agent: GOAPAgent) -> void:
	if not actions_container:
		return

	# Clear existing actions
	for child in actions_container.get_children():
		child.queue_free()

	# Get plan
	var plan: Array[GOAPAction] = []
	var current_index := 0

	if agent._executor and agent._executor.is_running():
		plan = agent._executor._plan if agent._executor._plan else []
		current_index = agent._executor.get_current_index()

	if plan.is_empty():
		var no_plan_label := Label.new()
		no_plan_label.text = "[color=gray]No active plan[/color]"
		no_plan_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		actions_container.add_child(no_plan_label)
		return

	# Create action nodes
	for i in range(plan.size()):
		var action := plan[i]
		var action_node := _create_action_node(action, i, current_index)
		actions_container.add_child(action_node)

		# Add arrow between actions
		if i < plan.size() - 1:
			var arrow := _create_arrow()
			actions_container.add_child(arrow)


## Creates an action node display.[br][br]
##
## [param action] Action to display.[br]
## [param index] Index in plan.[br]
## [param current_index] Current execution index.[br]
## [br]
## Returns action node Control.
func _create_action_node(action: GOAPAction, index: int, current_index: int) -> Control:
	var panel := PanelContainer.new()

	# Set background color based on status
	var status := _get_action_status(index, current_index)
	var style_box := StyleBoxFlat.new()

	match status:
		"completed":
			style_box.bg_color = Color(0.2, 0.4, 0.2, 0.5)
		"current":
			style_box.bg_color = Color(0.4, 0.6, 0.2, 0.7)
		"pending":
			style_box.bg_color = Color(0.2, 0.2, 0.2, 0.5)

	style_box.corner_radius_top_left = 4
	style_box.corner_radius_top_right = 4
	style_box.corner_radius_bottom_left = 4
	style_box.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style_box)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Header: index + name + cost
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var index_label := Label.new()
	index_label.text = "[%d]" % (index + 1)
	index_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	header.add_child(index_label)

	var name_label := Label.new()
	name_label.text = action.action_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var cost_label := Label.new()
	cost_label.text = "cost: %.1f" % action.cost
	cost_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
	header.add_child(cost_label)

	# Show details if enabled
	if show_details_checkbox and show_details_checkbox.button_pressed:
		# Preconditions
		if not action.preconditions.is_empty():
			var precond_label := Label.new()
			precond_label.text = "Pre: " + _format_conditions(action.preconditions)
			precond_label.add_theme_font_size_override("font_size", 11)
			precond_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.9))
			vbox.add_child(precond_label)

		# Effects
		if not action.effects.is_empty():
			var effects_label := Label.new()
			effects_label.text = "Eff: " + _format_conditions(action.effects)
			effects_label.add_theme_font_size_override("font_size", 11)
			effects_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
			vbox.add_child(effects_label)

	return panel


## Creates an arrow separator between actions.[br][br]
##
## Returns arrow Control.
func _create_arrow() -> Control:
	var arrow := Label.new()
	arrow.text = "↓"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 20)
	arrow.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	return arrow


## Gets action status based on execution index.[br][br]
##
## [param index] Action index.[br]
## [param current_index] Current execution index.[br]
## [br]
## Returns status string.
func _get_action_status(index: int, current_index: int) -> String:
	if index < current_index:
		return "completed"
	elif index == current_index:
		return "current"
	else:
		return "pending"


## Formats conditions dictionary for display.[br][br]
##
## [param conditions] Conditions dictionary.[br]
## [br]
## Returns formatted string.
func _format_conditions(conditions: Dictionary) -> String:
	var parts: Array[String] = []
	for key in conditions:
		var value = conditions[key]
		parts.append("%s=%s" % [key, str(value)])
	return ", ".join(parts)


## Clears all display fields.
func _clear_display() -> void:
	_current_agent = null

	if goal_label:
		goal_label.text = "-"
	if plan_size_label:
		plan_size_label.text = "0 actions"
	if total_cost_label:
		total_cost_label.text = "0.0"
	if progress_label:
		progress_label.text = "0 / 0"

	if actions_container:
		for child in actions_container.get_children():
			child.queue_free()


## Sets auto-refresh enabled.[br][br]
##
## [param enabled] Enable/disable auto-refresh.
func set_auto_refresh(enabled: bool) -> void:
	_auto_refresh = enabled


## Signal handlers

func _on_refresh_pressed() -> void:
	if _current_agent:
		refresh(_current_agent)


func _on_show_details_toggled(_toggled_on: bool) -> void:
	if _current_agent:
		refresh(_current_agent)
