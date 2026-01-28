## Main debug overlay UI for GOAP system.
##
## Provides a toggleable overlay with tabbed panels for debugging.[br]
## Press F3 to toggle visibility.[br][br]
##
## [b]Features:[/b]
## - Agent selector dropdown
## - Tabbed interface for different debug panels
## - Resizable and draggable panels
## - Persistent layout configuration
## - Keyboard shortcuts (F3 to toggle)[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## # Overlay is loaded automatically by GOAPDebugAutoload
## GOAPDebugManager.show_debug_overlay()
## GOAPDebugManager.hide_debug_overlay()
## GOAPDebugManager.toggle_debug_overlay()
## [/codeblock]
extends Control

## Config file path for saving layout.
const CONFIG_PATH: String = "user://goap_debug_config.cfg"

## Reference to agent selector dropdown.
@onready var agent_selector: OptionButton = %AgentSelector

## Reference to tab container.
@onready var tab_container: TabContainer = %TabContainer

## Reference to agent state panel.
@onready var agent_state_panel: Control = %AgentStatePanel

## Reference to blackboard inspector.
@onready var blackboard_inspector: Control = %BlackboardInspector

## Reference to plan visualizer.
@onready var plan_visualizer: Control = %PlanVisualizer

## Reference to timeline viewer.
@onready var timeline_viewer: Control = %TimelineViewer

## Reference to performance monitor.
@onready var performance_monitor: Control = %PerformanceMonitor

## Reference to event log.
@onready var event_log: Control = %EventLog

## Currently selected agent.
var _selected_agent: GOAPAgent = null

## Configuration object.
var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	# Start hidden
	hide()

	# Load configuration
	_load_config()

	# Setup agent selector
	_setup_agent_selector()

	# Connect to debug manager signals
	if GOAPDebugManager:
		GOAPDebugManager.agent_registered.connect(_on_agent_registered)
		GOAPDebugManager.agent_unregistered.connect(_on_agent_unregistered)
		GOAPDebugManager.debug_event_recorded.connect(_on_debug_event_recorded)

	# Connect UI signals
	if agent_selector:
		agent_selector.item_selected.connect(_on_agent_selected)

	print("[GOAPDebugOverlay] Overlay ready")


func _input(event: InputEvent) -> void:
	# Toggle on F3
	if event is InputEventKey:
		if event.keycode == KEY_F3 and event.pressed and not event.echo:
			visible = not visible
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_config()


## Refreshes all panels with current agent data.
func refresh_all_panels() -> void:
	if not _selected_agent:
		return

	if agent_state_panel and agent_state_panel.has_method("refresh"):
		agent_state_panel.refresh(_selected_agent)

	if blackboard_inspector and blackboard_inspector.has_method("refresh"):
		blackboard_inspector.refresh(_selected_agent)

	if plan_visualizer and plan_visualizer.has_method("refresh"):
		plan_visualizer.refresh(_selected_agent)

	if timeline_viewer and timeline_viewer.has_method("refresh"):
		timeline_viewer.refresh(_selected_agent)

	if performance_monitor and performance_monitor.has_method("refresh"):
		performance_monitor.refresh(_selected_agent)


## Sets the selected agent.[br][br]
##
## [param agent] Agent to select.
func set_selected_agent(agent: GOAPAgent) -> void:
	_selected_agent = agent
	refresh_all_panels()


## Gets the currently selected agent.[br][br]
##
## Returns selected agent or null.
func get_selected_agent() -> GOAPAgent:
	return _selected_agent


## Sets up the agent selector dropdown.
func _setup_agent_selector() -> void:
	if not agent_selector:
		return

	agent_selector.clear()

	# Add all registered agents
	if GOAPDebugManager:
		var agents := GOAPDebugManager.get_all_agents()
		for i in range(agents.size()):
			var agent := agents[i]
			agent_selector.add_item(agent.name, i)

		# Select first agent if available
		if agents.size() > 0:
			agent_selector.select(0)
			_selected_agent = agents[0]
			refresh_all_panels()


## Loads configuration from file.
func _load_config() -> void:
	var err := _config.load(CONFIG_PATH)
	if err != OK:
		print("[GOAPDebugOverlay] No config found, using defaults")
		return

	# Restore window position
	if _config.has_section_key("layout", "position_x") and _config.has_section_key("layout", "position_y"):
		position.x = _config.get_value("layout", "position_x")
		position.y = _config.get_value("layout", "position_y")

	# Restore window size
	if _config.has_section_key("layout", "size_x") and _config.has_section_key("layout", "size_y"):
		size.x = _config.get_value("layout", "size_x")
		size.y = _config.get_value("layout", "size_y")

	# Restore selected tab
	if _config.has_section_key("layout", "selected_tab") and tab_container:
		var tab_index: int = _config.get_value("layout", "selected_tab")
		tab_container.current_tab = tab_index

	print("[GOAPDebugOverlay] Configuration loaded")


## Saves configuration to file.
func _save_config() -> void:
	# Save window position
	_config.set_value("layout", "position_x", position.x)
	_config.set_value("layout", "position_y", position.y)

	# Save window size
	_config.set_value("layout", "size_x", size.x)
	_config.set_value("layout", "size_y", size.y)

	# Save selected tab
	if tab_container:
		_config.set_value("layout", "selected_tab", tab_container.current_tab)

	var err := _config.save(CONFIG_PATH)
	if err == OK:
		print("[GOAPDebugOverlay] Configuration saved")
	else:
		push_error("[GOAPDebugOverlay] Failed to save configuration: ", err)


## Signal handlers

func _on_agent_registered(_agent: GOAPAgent) -> void:
	_setup_agent_selector()


func _on_agent_unregistered(agent: GOAPAgent) -> void:
	if _selected_agent == agent:
		_selected_agent = null
	_setup_agent_selector()


func _on_agent_selected(index: int) -> void:
	if not GOAPDebugManager:
		return

	var agents := GOAPDebugManager.get_all_agents()
	if index >= 0 and index < agents.size():
		set_selected_agent(agents[index])


func _on_debug_event_recorded(event: DebugEvent) -> void:
	# Forward event to relevant panels
	if event.agent == _selected_agent:
		refresh_all_panels()

	# Always update event log
	if event_log and event_log.has_method("add_event"):
		event_log.add_event(event)
