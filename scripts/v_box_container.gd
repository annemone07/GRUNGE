extends VBoxContainer

var player: int = 1
var boxId: int = 0
var was_listening: bool = false
var cooldown_timer: float = 0.0 

func _ready() -> void:
	await get_tree().process_frame
	_update_selection_visual()

func _process(delta: float) -> void:
	var children = get_children()
	var menu_size = children.size()
	
	if menu_size == 0 or player == 0:
		return

	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		return

	var is_any_listening = false
	for child in children:
		if child.get("listening") == true:
			is_any_listening = true
			break

	if is_any_listening:
		was_listening = true
		return

	
	if was_listening:
		was_listening = false
		cooldown_timer = 0.4
		return

	var action_up = "customAction_player" + str(player) + "_up"
	var action_down = "customAction_player" + str(player) + "_down"
	var action_select = "customAction_player" + str(player) + "_select"
	var action_back = "customAction_player" + str(player) + "_back"

	var moved = false

	if Input.is_action_just_pressed(action_up):
		boxId -= 1
		if boxId < 0:
			boxId = menu_size - 1
		moved = true

	elif Input.is_action_just_pressed(action_down):
		boxId += 1
		if boxId >= menu_size:
			boxId = 0
		moved = true

	elif Input.is_action_just_pressed(action_select):
		var target_btn = children[boxId]
		if target_btn is Button:
			target_btn.emit_signal("pressed")
			was_listening = true

	elif Input.is_action_just_pressed(action_back):
		var parent_scene = get_parent()
		if parent_scene and parent_scene.has_method("_on_button_pressed"):
			parent_scene._on_button_pressed()

	if moved:
		_update_selection_visual()

func _update_selection_visual() -> void:
	var children = get_children()
	for i in range(children.size()):
		var child = children[i]
		if child is Button:
			child.flat = (i != boxId)
