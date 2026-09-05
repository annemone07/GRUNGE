extends Node3D

# Carrega a sua nova cena modular
const MUSIC_ITEM_SCENE = preload("res://scenes/music_sel.tscn")

@onready var vbox_container = $selectMusicScreen/HBoxContainer

func _ready() -> void:
	for child in vbox_container.get_children():
		child.queue_free()
		
	_populate_music_list()

func _populate_music_list() -> void:
	for m_id in Globals.music_database:
		var music_data = Globals.music_database[m_id]
		
		var item = MUSIC_ITEM_SCENE.instantiate()
		vbox_container.add_child(item)
		
		item.setup(m_id, music_data["title"], music_data["high_score"])
		item.music_selected.connect(_on_music_item_selected)
		
	if vbox_container.get_child_count() > 0:
		var primeiro_item = vbox_container.get_child(0)
		if "btn_play" in primeiro_item and primeiro_item.btn_play:
			primeiro_item.btn_play.grab_focus()

func _unhandled_input(_event: InputEvent) -> void:
	# 1. Confirmação (P1, P2 ou UI padrão)
	var is_select = Input.is_action_just_pressed("customAction_player1_select") or \
					Input.is_action_just_pressed("customAction_player2_select") or \
					Input.is_action_just_pressed("ui_accept")
					
	if is_select:
		var focused_node = get_viewport().gui_get_focus_owner()
		if focused_node and focused_node is Button:
			get_viewport().set_input_as_handled()
			focused_node.emit_signal("pressed")

	# 2. Voltar para a tela anterior (P1, P2 ou UI cancel)
	var is_back = Input.is_action_just_pressed("customAction_player1_back") or \
				  Input.is_action_just_pressed("customAction_player2_back") or \
				  Input.is_action_just_pressed("ui_cancel")

	if is_back:
		get_viewport().set_input_as_handled()
		_go_back_to_gamemode()

func _go_back_to_gamemode() -> void:
	var stage_scene = load("res://scenes/gamemode.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()

func _on_music_item_selected(selected_id: String) -> void:
	Globals.selected_music = selected_id
	change_scene_to_instruments()

func change_scene_to_instruments() -> void:
	var stage_scene = load("res://scenes/selectCharacters.tscn")
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id = main_node.get_child_count() - 1
		var stage = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar a cena.")
