extends VBoxContainer

var player: int = 1
var boxId: int = 0

func _ready() -> void:
	# Aguarda 1 frame para garantir que o controles.gd terminou de configurar os nomes e player
	await get_tree().process_frame
	_update_selection_visual()

func _process(_delta: float) -> void:
	var children = get_children()
	var menu_size = children.size()
	
	if menu_size == 0 or player == 0:
		return

	# Se qlqr botão estiver esperando o input
	# bloqueia a navegação do menu para não mover a seleção nem reativar o clique.
	for child in children:
		if child is ReconfigKey and child.listening:
			return

	var action_up = "customAction_player" + str(player) + "_up"
	var action_down = "customAction_player" + str(player) + "_down"
	var action_select = "customAction_player" + str(player) + "_select"

	var moved = false

	if Input.is_action_just_pressed(action_up):
		boxId -= 1
		if boxId < 0:
			boxId = menu_size - 1 # Dá a volta para o final da lista
		moved = true

	elif Input.is_action_just_pressed(action_down):
		boxId += 1
		if boxId >= menu_size:
			boxId = 0 # Dá a volta para o início da lista
		moved = true

	elif Input.is_action_just_pressed(action_select):
		var target_btn = children[boxId]
		if target_btn is Button:
			target_btn.emit_signal("pressed")

	if moved:
		_update_selection_visual()

func _update_selection_visual() -> void:
	var children = get_children()
	for i in range(children.size()):
		var child = children[i]
		if child is Button:
			# pra destacar o botão selecionado deixando ele normal (flat = false) 
			# e os outros transparentes (flat = true)
			child.flat = (i != boxId)
