# controls.gd (autoload)
extends Node

const banned_buttons = []
const REBINDABLE = ["customAction_player1_bt1", "customAction_player1_bt2", "customAction_player1_bt3", 
"customAction_player1_bt4", "customAction_player1_bt5", "customAction_player1_bt6", "customAction_player1_bt7",
"customAction_player1_bt8","customAction_player1_pedal", "customAction_player2_bt1", "customAction_player2_bt2",
"customAction_player2_bt3","customAction_player2_bt4", "customAction_player2_bt5", "customAction_player2_bt6",
"customAction_player2_bt7", "customAction_player2_bt8","customAction_player2_pedal"]
const CONFIG_PATH = "user://input.cfg"

func save_bindings():
	var cfg = ConfigFile.new()
	for action in REBINDABLE:
		var events = InputMap.action_get_events(action)
		cfg.set_value("bindings", action, events)
		print(cfg.get_value("bindings",action,events))
	cfg.save(CONFIG_PATH)
	
func _ready():	
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return

	for action in REBINDABLE:
		if not InputMap.has_action(action):
			continue
		var events = cfg.get_value("bindings", action, [])
		if events.is_empty():
			continue
		InputMap.action_erase_events(action)
		for event in events:
			InputMap.action_add_event(action, event)

func rebind_keyboard(action: String, new_event: InputEvent):
	var alreadyMapped=false
	for mappedAction in REBINDABLE:
		for mappedEvent in InputMap.action_get_events(mappedAction):
			if mappedEvent is InputEventKey and new_event is InputEventKey:
				if mappedEvent.physical_keycode==new_event.keycode:
					alreadyMapped=true
			elif mappedEvent is InputEventJoypadButton and new_event is InputEventJoypadButton:
				if mappedEvent.button_index==new_event.button_index:
					alreadyMapped=true
	if not alreadyMapped and (new_event is InputEventKey or new_event is InputEventJoypadButton) and new_event.keycode!=KEY_ENTER and new_event.keycode!=KEY_BACKSLASH:
		var existing = InputMap.action_get_events(action)
		for event in existing:
			InputMap.action_erase_event(action, event)
		InputMap.action_add_event(action, new_event)
	save_bindings()
