## Reusable debug UI overlay for GOAP playgrounds.
##
## Displays:[br]
## - Current agent state and plan[br]
## - Blackboard contents[br]
## - Performance metrics[br]
## - Playground-specific custom metrics[br][br]
##
## Toggleable with F1 key via [PlaygroundBase].
class_name DebugOverlay
extends CanvasLayer

## Panel container for all debug UI.
var _panel: PanelContainer

## VBox containing all debug sections.
var _vbox: VBoxContainer

## Label for agent state display.
var _agent_label: RichTextLabel

## Label for blackboard state display.
var _blackboard_label: RichTextLabel

## Label for performance metrics.
var _metrics_label: RichTextLabel

## Currently inspected agent.
var _inspected_agent: GOAPAgent = null


func _ready() -> void:
	layer = 100  # Ensure overlay is on top

	# Create panel
	_panel = PanelContainer.new()
	_panel.anchor_right = 0.3
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 10
	_panel.offset_top = 10
	_panel.offset_right = -10
	_panel.offset_bottom = -10
	add_child(_panel)

	# Create scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(scroll)

	# Create VBox
	_vbox = VBoxContainer.new()
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_vbox)

	# Title
	var title := Label.new()
	title.text = "GOAP Playground Debug"
	title.add_theme_font_size_override("font_size", 16)
	_vbox.add_child(title)

	_vbox.add_child(HSeparator.new())

	# Agent state section
	var agent_header := Label.new()
	agent_header.text = "Selected Agent (click to select)"
	agent_header.add_theme_font_size_override("font_size", 14)
	_vbox.add_child(agent_header)

	_agent_label = RichTextLabel.new()
	_agent_label.bbcode_enabled = true
	_agent_label.fit_content = true
	_agent_label.custom_minimum_size = Vector2(0, 100)
	_agent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_child(_agent_label)

	_vbox.add_child(HSeparator.new())

	# Blackboard section
	var bb_header := Label.new()
	bb_header.text = "Blackboard State"
	bb_header.add_theme_font_size_override("font_size", 14)
	_vbox.add_child(bb_header)

	_blackboard_label = RichTextLabel.new()
	_blackboard_label.bbcode_enabled = true
	_blackboard_label.fit_content = true
	_blackboard_label.custom_minimum_size = Vector2(0, 150)
	_blackboard_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_child(_blackboard_label)

	_vbox.add_child(HSeparator.new())

	# Metrics section
	var metrics_header := Label.new()
	metrics_header.text = "Performance Metrics"
	metrics_header.add_theme_font_size_override("font_size", 14)
	_vbox.add_child(metrics_header)

	_metrics_label = RichTextLabel.new()
	_metrics_label.bbcode_enabled = true
	_metrics_label.fit_content = true
	_metrics_label.custom_minimum_size = Vector2(0, 100)
	_metrics_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox.add_child(_metrics_label)


func _process(_delta: float) -> void:
	if visible and _inspected_agent:
		_update_agent_display()
		_update_blackboard_display()


## Sets the agent to inspect in the debug overlay.
func set_inspected_agent(agent: GOAPAgent) -> void:
	_inspected_agent = agent
	if not agent:
		_agent_label.text = "[color=gray]No agent selected[/color]"
		_blackboard_label.text = ""


## Updates performance metrics display.
func update_metrics(metrics: Dictionary) -> void:
	if not visible:
		return

	var text := ""
	text += "[b]FPS:[/b] %d\n" % Performance.get_monitor(Performance.TIME_FPS)
	text += "[b]Time Scale:[/b] %.1fx\n" % Engine.time_scale

	for key in metrics:
		var value = metrics[key]
		if value is float:
			text += "[b]%s:[/b] %.2f\n" % [key, value]
		elif value is int:
			text += "[b]%s:[/b] %d\n" % [key, value]
		else:
			text += "[b]%s:[/b] %s\n" % [key, str(value)]

	_metrics_label.text = text


## Updates agent state display.
func _update_agent_display() -> void:
	if not _inspected_agent or not is_instance_valid(_inspected_agent):
		_agent_label.text = "[color=red]Agent invalid[/color]"
		return

	var text := ""
	var state := _inspected_agent.get_state()
	var state_name := ""

	match state:
		GOAPAgent.State.IDLE:
			state_name = "[color=gray]IDLE[/color]"
		GOAPAgent.State.PLANNING:
			state_name = "[color=yellow]PLANNING[/color]"
		GOAPAgent.State.PERFORMING:
			state_name = "[color=green]PERFORMING[/color]"

	text += "[b]State:[/b] %s\n" % state_name

	# Current goal
	if _inspected_agent.current_goal:
		text += "[b]Goal:[/b] %s\n" % _inspected_agent.current_goal.goal_name
		var priority := _inspected_agent.current_goal.get_priority(_inspected_agent.blackboard.to_ref())
		text += "[b]Priority:[/b] %.2f\n" % priority
	else:
		text += "[b]Goal:[/b] [color=gray]None[/color]\n"

	# Current action
	var current_action := _inspected_agent.get_current_action()
	if current_action:
		text += "[b]Action:[/b] %s\n" % current_action.action_name
	else:
		text += "[b]Action:[/b] [color=gray]None[/color]\n"

	_agent_label.text = text


## Updates blackboard display.
func _update_blackboard_display() -> void:
	if not _inspected_agent or not is_instance_valid(_inspected_agent):
		_blackboard_label.text = ""
		return

	var bb := _inspected_agent.blackboard.to_ref()
	if bb.is_empty():
		_blackboard_label.text = "[color=gray]Empty[/color]"
		return

	var text := ""
	var keys := bb.keys()
	keys.sort()

	for key in keys:
		var value = bb[key]
		var value_str := str(value)

		# Color code by type
		if value is bool:
			value_str = "[color=cyan]%s[/color]" % value
		elif value is int or value is float:
			value_str = "[color=yellow]%s[/color]" % value
		elif value is String or value is StringName:
			value_str = "[color=green]\"%s\"[/color]" % value

		text += "[b]%s:[/b] %s\n" % [key, value_str]

	_blackboard_label.text = text
