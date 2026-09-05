class_name ReconfigKey
extends Button

var action_name: String = ""
var listening: bool = false

func _ready() -> void:
	update_button_text()

func _pressed() -> void:
	listening = true
	text = "Pressione um botão..."

func _unhandled_input(event: InputEvent) -> void:
	if not listening:
		return

	var is_valid = false

	# TECLADO
	if event is InputEventKey and event.is_pressed():
		if event.physical_keycode != KEY_ENTER and event.physical_keycode != KEY_BACKSLASH:
			is_valid = true

	# BOTÕES DO CONTROLE (A, B, X, Y, LB, RB, D-Pad, etc.)
	elif event is InputEventJoypadButton and event.is_pressed():
		is_valid = true

	# LT e RT do Xbox
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

	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		text = action_name + ": " + events[0].as_text()
	else:
		text = action_name + ": Sem comando"
