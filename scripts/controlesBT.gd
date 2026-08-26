extends Button

var listening: bool = false

func _ready() -> void:
	update_button_text()

func _pressed() -> void:
	listening = true
	text = "Press any key"
	grab_focus()
	
	update_button_text()
	release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not listening:
		return
		
	if event is InputEventKey or event is InputEventJoypadButton:
		ControlesAutoload.rebind_keyboard(name,event)
		
		listening = false
		button_pressed = false
		update_button_text()
		release_focus()

func update_button_text() -> void:
	var events = InputMap.action_get_events(name)
	if events.size() > 0:
		text = name + ": " + events[0].as_text()
	else:
		text = "Unassigned"
