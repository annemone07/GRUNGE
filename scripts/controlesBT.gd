
class_name ReconfigKey
extends Button

var action_name: String = ""
var listening: bool = false

func _ready() -> void:
	update_button_text()

func _pressed() -> void:
	print("a")
	listening = true
	text = "Aperte o botão..."

func _unhandled_input(event: InputEvent) -> void:
	if not listening:
		return

	var is_valid = false
	
	var deviceNum1 = 0
	var deviceNum2 = 0
	if InputMap.action_get_events("customAction_player1_select")[0] is InputEventKey:
		deviceNum1 = InputMap.action_get_events("customAction_player1_select")[0].keycode
	elif InputMap.action_get_events("customAction_player1_select")[0] is InputEventJoypadButton:
		deviceNum1 = InputMap.action_get_events("customAction_player1_select")[0].button_index
	elif InputMap.action_get_events("customAction_player1_select")[0] is InputEventJoypadMotion:
		deviceNum1 = InputMap.action_get_events("customAction_player1_select")[0].axis
	if InputMap.action_get_events("customAction_player2_select")[0] is InputEventKey:
		deviceNum2 = InputMap.action_get_events("customAction_player2_select")[0].keycode
	elif InputMap.action_get_events("customAction_player2_select")[0] is InputEventJoypadButton:
		deviceNum2 = InputMap.action_get_events("customAction_player2_select")[0].button_index
	elif InputMap.action_get_events("customAction_player2_select")[0] is InputEventJoypadMotion:
		deviceNum2 = InputMap.action_get_events("customAction_player2_select")[0].axis
		
	if event is InputEventKey and event.is_pressed():
		if event.keycode != deviceNum1 and event.keycode != deviceNum2:
			is_valid = true

	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index != deviceNum1 and event.keycode != deviceNum2:
			is_valid = true

	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		is_valid = true

	if is_valid:
		get_viewport().set_input_as_handled()
		var target_action = action_name if action_name != "" else name
		ControlesAutoload.rebind_keyboard(target_action, event)
		listening = false
		button_pressed = false
		update_button_text()
		release_focus()

func update_button_text() -> void:
	if action_name == "" or not InputMap.has_action(action_name):
		return

	var friendly_name = ControlesAutoload.ACTION_NAMES.get(action_name, action_name)
	var events = InputMap.action_get_events(action_name)
	
	if events.size() > 0:
		var key_text = _format_event_string(events[0])
		text = friendly_name + ": " + key_text
	else:
		text = friendly_name + ": Nulo"

func _format_event_string(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventJoypadButton:
		return "Btn " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		return "Eixo " + str(event.axis)
	return event.as_text()    
