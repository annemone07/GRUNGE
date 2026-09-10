extends Node

const banned_buttons = []

const REBINDABLE = [
	# Player 1 - Gameplay
	"customAction_player1_bt1", "customAction_player1_bt2", "customAction_player1_bt3", 
	"customAction_player1_bt4", "customAction_player1_bt5", "customAction_player1_bt6", 
	"customAction_player1_bt7", "customAction_player1_bt8", "customAction_player1_pedal",
	# Player 1 - Menu
	"customAction_player1_up", "customAction_player1_down", "customAction_player1_left", 
	"customAction_player1_right", "customAction_player1_select", "customAction_player1_back",
	
	# Player 2 - Gameplay
	"customAction_player2_bt1", "customAction_player2_bt2", "customAction_player2_bt3",
	"customAction_player2_bt4", "customAction_player2_bt5", "customAction_player2_bt6", 
	"customAction_player2_bt7", "customAction_player2_bt8", "customAction_player2_pedal",
	# Player 2 - Menu
	"customAction_player2_up", "customAction_player2_down", "customAction_player2_left", 
	"customAction_player2_right", "customAction_player2_select", "customAction_player2_back"
]

const ACTION_NAMES = {
	"customAction_player1_bt1": "Botão 1",
	"customAction_player1_bt2": "Botão 2",
	"customAction_player1_bt3": "Botão 3",
	"customAction_player1_bt4": "Botão 4",
	"customAction_player1_bt5": "Botão 5",
	"customAction_player1_bt6": "Botão 6",
	"customAction_player1_bt7": "Botão 7",
	"customAction_player1_bt8": "Botão 8",
	"customAction_player1_pedal": "Pedal",
	"customAction_player1_up": "Cima",
	"customAction_player1_down": "Baixo",
	"customAction_player1_left": "Esquerda",
	"customAction_player1_right": "Direita",
	"customAction_player1_select": "Confirmar",
	"customAction_player1_back": "Voltar",

	"customAction_player2_bt1": "Botão 1",
	"customAction_player2_bt2": "Botão 2",
	"customAction_player2_bt3": "Botão 3",
	"customAction_player2_bt4": "Botão 4",
	"customAction_player2_bt5": "Botão 5",
	"customAction_player2_bt6": "Botão 6",
	"customAction_player2_bt7": "Botão 7",
	"customAction_player2_bt8": "Botão 8",
	"customAction_player2_pedal": "Pedal",
	"customAction_player2_up": "Cima",
	"customAction_player2_down": "Baixo",
	"customAction_player2_left": "Esquerda",
	"customAction_player2_right": "Direita",
	"customAction_player2_select": "Confirmar",
	"customAction_player2_back": "Voltar"
}

const CONFIG_PATH = "user://input.cfg"

func save_bindings():
	var cfg = ConfigFile.new()
	for action in REBINDABLE:
		var events = InputMap.action_get_events(action)
		cfg.set_value("bindings", action, events)
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

func _is_menu_action(action: String) -> bool:
	return action.ends_with("_up") or action.ends_with("_down") or action.ends_with("_left") or action.ends_with("_right") or action.ends_with("_select") or action.ends_with("_back")

func _get_player_id(action: String) -> String:
	if "player1" in action:
		return "player1"
	elif "player2" in action:
		return "player2"
	return ""

func rebind_keyboard(action: String, new_event: InputEvent):

	var target_is_menu = _is_menu_action(action)
	var target_player = _get_player_id(action)

	var alreadyMapped = false
	for mappedAction in REBINDABLE:
		if mappedAction == action:
			continue
			
		var mapped_is_menu = _is_menu_action(mappedAction)
		var mapped_player = _get_player_id(mappedAction)

		if target_player != mapped_player or target_is_menu != mapped_is_menu:
			continue

		for mappedEvent in InputMap.action_get_events(mappedAction):
			if mappedEvent is InputEventKey and new_event is InputEventKey:
				if mappedEvent.physical_keycode == new_event.physical_keycode:
					alreadyMapped = true
			elif mappedEvent is InputEventJoypadButton and new_event is InputEventJoypadButton:
				if mappedEvent.button_index == new_event.button_index:
					alreadyMapped = true
			elif mappedEvent is InputEventJoypadMotion and new_event is InputEventJoypadMotion:
				if mappedEvent.axis == new_event.axis:
					alreadyMapped = true

	if not alreadyMapped:
		var existing = InputMap.action_get_events(action)
		for event in existing:
			InputMap.action_erase_event(action, event)
		InputMap.action_add_event(action, new_event)
		save_bindings()
