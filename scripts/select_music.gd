extends Node3D

const MUSIC_ITEM_SCENE = preload("res://scenes/telas/select_music_panel.tscn")

@onready var vbox_container = $selectMusicScreen/HBoxContainer
@onready var control_moldura: Control = $controlMoldura
@onready var moldura_pos: Node2D = $controlMoldura/Node2D
@onready var moldura: TextureRect = $controlMoldura/Node2D/TextureRect2

var boxId: int = 0
var menuCards: Array = []
var menuButtons: Array = []
var menu_size: int = 0
var tween_movimento: Tween
var player_id: int = 1
var pode_interagir: bool = false
var last_stick_dir: Vector2 = Vector2.ZERO

# Mapeia o ID do item na lista -> dados completos da música (caminho do JSON oficial, áudio, etc.)
var songs_registry: Dictionary = {}

signal cursor_moveu(nome_personagem, player_id)

func _ready() -> void:
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
		
	_populate_music_list()
	
	control_moldura.z_index = 1
	
	if menuButtons.size() > 0:
		moldura_pos.position = menuButtons[0].position
		_atualizar_visual()
		_button_selected(menuButtons[0])
		
	get_tree().create_timer(0.1).timeout.connect(func(): pode_interagir = true)

func _process(_delta: float) -> void:
	if not pode_interagir or menu_size == 0:
		return
		
	var mudou_selecao := false
	var device_id := player_id - 1
	
	var raw_x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var raw_y := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	
	var stick_dir := Vector2.ZERO
	if abs(raw_x) > 0.5 or abs(raw_y) > 0.5:
		if abs(raw_x) > abs(raw_y):
			stick_dir.x = 1.0 if raw_x > 0 else -1.0
		else:
			stick_dir.y = 1.0 if raw_y > 0 else -1.0
			
	var analog_up := (stick_dir.y < 0 and last_stick_dir.y >= 0)
	var analog_down := (stick_dir.y > 0 and last_stick_dir.y <= 0)
	last_stick_dir = stick_dir
	
	if Input.is_action_just_pressed("customAction_player1_up") or Input.is_action_just_pressed("customAction_player2_up") or analog_up:
		boxId = maxi(0, boxId - 1)
		mudou_selecao = true
	elif Input.is_action_just_pressed("customAction_player1_down") or Input.is_action_just_pressed("customAction_player2_down") or analog_down:
		boxId = mini(menu_size - 1, boxId + 1)
		mudou_selecao = true
		
	if mudou_selecao:
		_atualizar_visual()
		if menuButtons.size() > boxId:
			menuButtons[boxId].grab_focus()
	
	if Input.is_action_just_pressed("customAction_player1_select") or Input.is_action_just_pressed("customAction_player2_select"):
		if menuButtons.size() > boxId and menuButtons[boxId] is Button:
			menuButtons[boxId].pressed.emit()

func _atualizar_visual() -> void:
	if menuCards.size() <= boxId:
		return
		
	var card_atual = menuCards[boxId]
	var posicao_alvo: Vector2 = card_atual.global_position + Vector2(card_atual.size.x / 2.0, card_atual.size.y / 2.0)
	
	if tween_movimento:
		tween_movimento.kill()
		
	tween_movimento = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween_movimento.tween_property(moldura_pos, "global_position", posicao_alvo, 0.15)
	
	var nome_base: String = card_atual.name.to_lower().replace("_card", "")
	cursor_moveu.emit(nome_base, player_id)

func _populate_music_list() -> void:
	songs_registry.clear()
	
	# 1. Carrega todas as músicas oficiais gerenciadas pelo SoundtrackFS (Galeria/Editor)
	var dynamic_songs := SoundtrackFS.scan_all_songs()
	for s in dynamic_songs:
		var m_id := "music_%d" % int(s["index"])
		var saved_score := 0
		if Globals.music_database.has(m_id):
			saved_score = int(Globals.music_database[m_id].get("high_score", 0))
		songs_registry[m_id] = {
			"id": m_id,
			"title": str(s["title"]),
			"high_score": saved_score,
			"json_path": str(s["official_json_path"]),
			"audio_path": str(s["audio_path"])
		}

	# 2. Fallback: se ainda não houver nenhuma música na pasta do SoundtrackFS, carrega as 3 padrão de res://assets/beatmaps/
	if songs_registry.is_empty():
		var local_bm := beatmaps.new()
		for m_id in ["music_1", "music_2", "music_3"]:
			var data := local_bm.load_song(m_id)
			if not data.is_empty():
				songs_registry[m_id] = {
					"id": m_id,
					"title": str(data.get("title", m_id)),
					"high_score": 0,
					"json_path": "",
					"audio_path": ""
				}

	for m_id in songs_registry.keys():
		var music_data: Dictionary = songs_registry[m_id]
		var item = MUSIC_ITEM_SCENE.instantiate()
		vbox_container.add_child(item)
		item.setup(m_id, music_data["title"], music_data["high_score"])
		item.music_selected.connect(func(id: String): _on_music_item_selected(id))
		
	menuCards = vbox_container.get_children()
	menuButtons.clear()
	menu_size = 0
	
	for child in menuCards:
		for childer in child.get_children():
			if childer is Button:
				menuButtons.append(childer)
				menu_size += 1
				
	for button in menuButtons:
		button.focus_entered.connect(func(): _button_selected(button))
		button.mouse_entered.connect(func(): _button_selected(button))
		button.focus_exited.connect(func(): _button_deselected(button))
		button.mouse_exited.connect(func(): _button_deselected(button))
		_aplicar_estilo_normal(button)

func _unhandled_input(_event: InputEvent) -> void:
	var is_select := Input.is_action_just_pressed("customAction_player1_select") or \
					 Input.is_action_just_pressed("customAction_player2_select") or \
					 Input.is_action_just_pressed("ui_accept")
					
	if is_select:
		var focused_node := get_viewport().gui_get_focus_owner()
		if focused_node and focused_node is Button:
			get_viewport().set_input_as_handled()
			focused_node.emit_signal("pressed")

	var is_back := Input.is_action_just_pressed("customAction_player1_back") or \
				   Input.is_action_just_pressed("customAction_player2_back") or \
				   Input.is_action_just_pressed("ui_cancel")

	if is_back:
		get_viewport().set_input_as_handled()
		_go_back_to_gamemode()

func _go_back_to_gamemode() -> void:
	var stage_scene := load("res://scenes/telas/gamemode_menu.tscn") as PackedScene
	var main_node := get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id := main_node.get_child_count() - 1
		var stage: Node = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()

func _on_music_item_selected(selected_id: String) -> void:
	Globals.selected_music = selected_id
	
	# Se a música veio da pasta dinâmica (SoundtrackFS), repassa os caminhos oficiais dela para o gameplay
	if songs_registry.has(selected_id) and songs_registry[selected_id]["json_path"] != "":
		Globals.set_meta("official_chart_path", songs_registry[selected_id]["json_path"])
		Globals.set_meta("official_audio_path", songs_registry[selected_id]["audio_path"])
	else:
		if Globals.has_meta("official_chart_path"):
			Globals.remove_meta("official_chart_path")
		if Globals.has_meta("official_audio_path"):
			Globals.remove_meta("official_audio_path")
			
	change_scene_to_instruments()

func change_scene_to_instruments() -> void:
	var stage_scene := load("res://scenes/telas/select_character_menu.tscn") as PackedScene
	var main_node := get_tree().root.get_node_or_null("Main")
	if main_node and stage_scene:
		var old_stage_id := main_node.get_child_count() - 1
		var stage: Node = stage_scene.instantiate()
		main_node.add_child(stage)
		main_node.get_child(old_stage_id).queue_free()
	else:
		print("Erro: Não conseguimos encontrar res://scenes/telas/select_character_menu.tscn")

func _button_selected(button: Node = null) -> void:
	var index := menuButtons.find(button)
	if index != -1 and index != boxId:
		boxId = index
		_atualizar_visual()

	if button:
		button.pivot_offset = button.size / 2
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)
		_aplicar_estilo_focado(button)
		
		var card := button.get_parent()
		if card in menuCards:
			card.rolando_texto = true
			card.tempo_scroll = 0.0

func _button_deselected(button: Node = null) -> void:
	if button:
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
		_aplicar_estilo_normal(button)
		
		var card := button.get_parent()
		if card in menuCards:
			card.rolando_texto = false
			button.text = card.texto_original

func _aplicar_estilo_normal(button: Button) -> void:
	var estilo := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", estilo)
	button.add_theme_stylebox_override("hover", estilo)
	button.add_theme_stylebox_override("focus", estilo)
	button.add_theme_color_override("font_color", Color.WHITE)

func _aplicar_estilo_focado(button: Button) -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 1)
	estilo.corner_radius_top_left = 12
	estilo.corner_radius_top_right = 12
	estilo.corner_radius_bottom_left = 12
	estilo.corner_radius_bottom_right = 12
	estilo.expand_margin_left = 10
	estilo.expand_margin_right = 10
	estilo.expand_margin_top = 5
	estilo.expand_margin_bottom = 5
	
	button.add_theme_stylebox_override("normal", estilo)
	button.add_theme_stylebox_override("hover", estilo)
	button.add_theme_stylebox_override("focus", estilo)
	button.add_theme_color_override("font_color", Color.WHITE)
