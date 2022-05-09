extends Node

# Change these settings
var presets := [Preset.new("Default", false), Preset.new("Custom")]
var selected_preset: Preset = presets[0]
var actions := {"pixelorama": MenuInputAction.new("", "", true, "nah", 0)}
var groups := {}
var ignore_actions := []
var ignore_ui_actions := true
var changeable_types := [true, true, true, false]
var multiple_menu_accelerators := false
var config_path := "user://cache.ini"
var config_file: ConfigFile


class Preset:
	var name := ""
	var customizable := true
	var bindings := {}
	var config_section := ""

	func _init(_name := "", _customizable := true) -> void:
		name = _name
		customizable = _customizable
		config_section = "shortcuts-%s" % name

		for action in InputMap.get_actions():
			bindings[action] = InputMap.get_action_list(action)

	func load_from_file() -> void:
		if !BetterInput.config_file:
			return
		if !customizable:
			return
		for action in bindings:
			var action_list = BetterInput.config_file.get_value(config_section, action, [null])
			if action_list != [null]:
				bindings[action] = action_list

	func change_action(action: String) -> void:
		bindings[action] = InputMap.get_action_list(action)
		if BetterInput.config_file and customizable:
			BetterInput.config_file.set_value(config_section, action, bindings[action])
			BetterInput.config_file.save(BetterInput.config_path)


class InputAction:
	var display_name := ""
	var group := ""
	var global := true

	func _init(_display_name := "", _group := "", _global := true) -> void:
		display_name = _display_name
		group = _group
		global = _global

	func update_ui(_action: String) -> void:
		pass

	func handle_input(_event: InputEvent, _action: String) -> bool:
		return false


class MenuInputAction:
	extends InputAction
	var node_path := ""
	var node: PopupMenu
	var menu_item_id := 0
	var echo := false

	func _init(
		_display_name := "",
		_group := "",
		_global := true,
		_node_path := "",
		_menu_item_id := 0,
		_echo := false
	) -> void:
		._init(_display_name, _group, _global)
		node_path = _node_path
		menu_item_id = _menu_item_id
		echo = _echo

	func get_menu_node(root: Node) -> void:
		var temp_node = root.get_node(node_path)
		if temp_node is PopupMenu:
			node = node
		elif temp_node is MenuButton:
			node = temp_node.get_popup()

	func update_ui(action: String) -> void:
		if !node:
			return
		var accel := 0
		var events := InputMap.get_action_list(action)
		for event in events:
			if event is InputEventKey:
				accel = event.get_scancode_with_modifiers()
				break
		node.set_item_accelerator(menu_item_id, accel)

	func handle_input(event: InputEvent, action: String) -> bool:
		if not node:
			return false
		if event.is_action_pressed(action):
			if event is InputEventKey:
				var acc: int = node.get_item_accelerator(menu_item_id)
				# If the event is the same as the menu item's accelerator, skip
				if acc == event.get_scancode_with_modifiers():
					return true
			node.emit_signal("id_pressed", menu_item_id)
			return true
		if event.is_action(action) and echo:
			if event.is_echo():
				var menu: PopupMenu = node
				node.emit_signal("id_pressed", menu_item_id)
				return true

		return false


class InputGroup:
	var parent_group := ""
	var tree_item: TreeItem

	func _init(_parent_group := "") -> void:
		parent_group = _parent_group


func _init() -> void:
	if !config_file:
		config_file = ConfigFile.new()
		if !config_path.empty():
			config_file.load(config_path)


func _ready() -> void:
	set_process_input(multiple_menu_accelerators)
	for action in actions:
		var input_action: InputAction = actions[action]
		if input_action is MenuInputAction:
			input_action.get_menu_node(get_tree().current_scene)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return

	for action in actions:
		var input_action: InputAction = actions[action]
		var done: bool = input_action.handle_input(event, action)
		if done:
			return


func action_add_event(action: String, new_event: InputEvent) -> void:
	InputMap.action_add_event(action, new_event)
	if action in actions:
		actions[action].update_ui(action)


func action_erase_event(action: String, event: InputEvent) -> void:
	InputMap.action_erase_event(action, event)
	if action in actions:
		actions[action].update_ui(action)


func action_erase_events(action: String) -> void:
	InputMap.action_erase_events(action)
	if action in actions:
		actions[action].update_ui(action)
