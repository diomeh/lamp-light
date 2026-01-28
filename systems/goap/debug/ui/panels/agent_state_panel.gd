## Agent state display panel for GOAP debug overlay.
##
## Shows current agent FSM state, goal, action, and plan progress.[br][br]
##
## [b]Displays:[/b]
## - Agent FSM state (IDLE/PLANNING/PERFORMING)
## - Current goal and priority
## - Current action
## - Plan progress
## - Available goals and actions[br][br]
##
## [b]Usage:[/b]
## [codeblock]
## agent_state_panel.refresh(agent)
## [/codeblock]
extends Control

## Label for agent state.
@onready var state_label: Label = %StateLabel

## Label for current goal.
@onready var goal_label: Label = %GoalLabel

## Label for goal priority.
@onready var priority_label: Label = %PriorityLabel

## Label for current action.
@onready var action_label: Label = %ActionLabel

## Label for plan progress.
@onready var progress_label: Label = %ProgressLabel

## Progress bar for plan completion.
@onready var progress_bar: ProgressBar = %ProgressBar

## Container for available goals list.
@onready var goals_list: ItemList = %GoalsList

## Container for available actions list.
@onready var actions_list: ItemList = %ActionsList

## Refresh button.
@onready var refresh_button: Button = %RefreshButton

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

	# Initial state
	_clear_display()


func _process(delta: float) -> void:
	if not _auto_refresh or not _current_agent:
		return

	_time_since_refresh += delta
	if _time_since_refresh >= _refresh_interval:
		refresh(_current_agent)
		_time_since_refresh = 0.0


## Refreshes panel with agent data.[br][br]
##
## [param agent] Agent to display.
func refresh(agent: GOAPAgent) -> void:
	if not agent or not is_instance_valid(agent):
		_clear_display()
		return

	_current_agent = agent

	# Update state
	if state_label:
		var state := agent.get_state()
		var state_str : String = GOAPAgent.State.keys()[state]
		var color := _get_state_color(state)
		state_label.text = "[color=%s]%s[/color]" % [color, state_str]

	# Update goal
	if goal_label:
		if agent.current_goal:
			goal_label.text = agent.current_goal.goal_name
		else:
			goal_label.text = "[color=gray]None[/color]"

	# Update priority
	if priority_label and agent.current_goal:
		var priority := agent.current_goal.get_priority(agent.blackboard.to_ref())
		priority_label.text = "%.1f" % priority
	elif priority_label:
		priority_label.text = "-"

	# Update current action
	if action_label:
		var current_action := agent.get_current_action()
		if current_action:
			action_label.text = current_action.action_name
		else:
			action_label.text = "[color=gray]None[/color]"

	# Update plan progress
	_update_plan_progress(agent)

	# Update goals list
	_update_goals_list(agent)

	# Update actions list
	_update_actions_list(agent)


## Updates plan progress display.[br][br]
##
## [param agent] Agent to get progress from.
func _update_plan_progress(agent: GOAPAgent) -> void:
	if not agent._executor or not agent._executor.is_running():
		if progress_label:
			progress_label.text = "0 / 0"
		if progress_bar:
			progress_bar.value = 0
		return

	var current_index := agent._executor.get_current_index()
	var total_actions := agent._executor._plan.size() if agent._executor._plan else 0

	if progress_label:
		progress_label.text = "%d / %d" % [current_index + 1, total_actions]

	if progress_bar:
		if total_actions > 0:
			progress_bar.max_value = total_actions
			progress_bar.value = current_index + 1
		else:
			progress_bar.value = 0


## Updates available goals list.[br][br]
##
## [param agent] Agent to get goals from.
func _update_goals_list(agent: GOAPAgent) -> void:
	if not goals_list:
		return

	goals_list.clear()

	var goals := agent.get_goals()
	for goal in goals:
		var priority := goal.get_priority(agent.blackboard.to_ref())
		var text := "%s (%.1f)" % [goal.goal_name, priority]
		goals_list.add_item(text)

		# Highlight current goal
		if agent.current_goal and goal == agent.current_goal:
			var index := goals_list.item_count - 1
			goals_list.set_item_custom_bg_color(index, Color(0.3, 0.5, 0.3, 0.3))


## Updates available actions list.[br][br]
##
## [param agent] Agent to get actions from.
func _update_actions_list(agent: GOAPAgent) -> void:
	if not actions_list:
		return

	actions_list.clear()

	var actions := agent.get_actions()
	for action in actions:
		var text := "%s (cost: %.1f)" % [action.action_name, action.cost]
		actions_list.add_item(text)

		# Highlight current action
		var current_action := agent.get_current_action()
		if current_action and action == current_action:
			var index := actions_list.item_count - 1
			actions_list.set_item_custom_bg_color(index, Color(0.3, 0.5, 0.3, 0.3))


## Clears all display fields.
func _clear_display() -> void:
	_current_agent = null

	if state_label:
		state_label.text = "-"
	if goal_label:
		goal_label.text = "-"
	if priority_label:
		priority_label.text = "-"
	if action_label:
		action_label.text = "-"
	if progress_label:
		progress_label.text = "0 / 0"
	if progress_bar:
		progress_bar.value = 0
	if goals_list:
		goals_list.clear()
	if actions_list:
		actions_list.clear()


## Gets color for agent state.[br][br]
##
## [param state] Agent state.[br]
## [br]
## Returns color hex string.
func _get_state_color(state: GOAPAgent.State) -> String:
	match state:
		GOAPAgent.State.IDLE:
			return "#888888"
		GOAPAgent.State.PLANNING:
			return "#FFAA00"
		GOAPAgent.State.PERFORMING:
			return "#00FF00"
		_:
			return "#FFFFFF"


## Sets auto-refresh enabled.[br][br]
##
## [param enabled] Enable/disable auto-refresh.
func set_auto_refresh(enabled: bool) -> void:
	_auto_refresh = enabled


## Signal handlers

func _on_refresh_pressed() -> void:
	if _current_agent:
		refresh(_current_agent)
