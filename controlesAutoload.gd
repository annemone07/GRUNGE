# controls.gd (autoload)
extends Node

const REBINDABLE = ["bt1", "bt2", "bt3", "bt4", "bt5", "bt6", "bt7", "bt8", "pedal"]
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
			continue  # keep defaults if nothing saved
		InputMap.action_erase_events(action)
		for ev in events:
			InputMap.action_add_event(action, ev)

func has_conflict(action: String, new_event: InputEvent) -> String:
	for other in REBINDABLE:
		if other == action: continue
		for ev in InputMap.action_get_events(other):
			if ev.is_match(new_event):
				return other
	return ""

func rebind_keyboard(action: String, new_event: InputEvent):
	var existing = InputMap.action_get_events(action)
	for ev in existing:
		if ev is InputEventKey or ev is InputEventJoypadButton:
			InputMap.action_erase_event(action, ev)
	InputMap.action_add_event(action, new_event)
	save_bindings()
